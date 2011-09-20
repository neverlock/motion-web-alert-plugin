#!/usr/bin/env python

# ShackShag 0.5, 2010-01-08
# http://code.google.com/p/shackshag/
# Author: Wiktor Bachnik, wiktor at bachnik dot com

# This software is released under GPL license:
# http://www.gnu.org/licenses/gpl.html
# Some inspiration and code snippets were taken from:
# http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/146306

# You're using this software at your own risk. The author shall not
# be held liable for ANY problems caused by using this software.
# Remember to read ImageShack Terms of Service before using their services
# It can be found at: http://reg.imageshack.us/content.php?page=rules

"""
ShackShag - imageshack batch image uploader.
"""

__version__ = "$Revision: 13 $"
# $Source$

import sys, os, httplib, mimetypes, re
from optparse import OptionParser, OptionValueError

# what this script is pretending to be
USER_AGENT = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.12) Gecko/20050922 Firefox/1.0.7 (Debian package 1.0.7-1)"
# where did we come from? Send in HTTP header when uploading image
REFERER = 'http://imageshack.us/'
# imageshack host
HOST = 'imageshack.us'
UPLOAD_PATH = '/'
# form fields that should be sent every time
BASIC_FORM_FIELDS = [
    ('MAX_FILE_SIZE', '13145728'),
    ('refer', ''),
    ('brand', ''),
    ('email', ''),
    ('submit', 'host it!')
]
# option for "remove size/resolution bar from thumbnail" setting
REMOVE_THUMB_BAR_FIELD = ('rembar', '1')
# indices in the image links tuple
IDX_DIRECT_LINK = 0
IDX_THUMBNAIL_LINK = 1
# default number of upload attempts
DEFAULT_NUM_TRIES = 5

class NoMatchError(Exception):
    """Exception raised when image link can't be matched in the results page
    after upload."""
    pass

class UploadFlowError(Exception):
    """Exception raised when code failes to follow flow of the upload process."""
    pass

class UnexpectedServerCodeError(Exception):
    """Exception raised when server returns unrecognized response code."""
    def __init__(self, code):
        self.code = code
    def __str__(self):
        return repr(self.code)

def send_form_with_file(host, path, headers, form_body):
    """Sends POST request containing file upload to the specified server using 
    provided headers and form body."""

    conn = httplib.HTTPConnection(host)
    conn.putrequest('POST', path)
    for header in headers.keys():
        conn.putheader(header, headers[header])
    conn.endheaders()
    conn.send(form_body)
    response = conn.getresponse()
    conn.close()
    return response

def encode_multipart_formdata(fields, file_data):
    """Performs multipart encoding of form fields and uploaded file contents.
    Parameters:
    fields -- list of field name and field value pairs
    file_data -- contents of the uploaded file.
    
    Returns: tuple with content type string and MIME encoded form body.
    """
    boundary = '----------HappyHappy__bouNdaRY_$'
    crlf = '\r\n'
    lines = []
    # add additional form fields
    for (key, value) in fields:
        lines.append('--' + boundary)
        lines.append('Content-Disposition: form-data; name="%s"' % key)
        lines.append('')
        lines.append(value)
    # add file
    lines.append('--' + boundary)
    lines.append('Content-Disposition: form-data; name="%s"; filename="%s"'
        % (file_data[0], file_data[1]))
    lines.append('Content-Type: %s' % get_content_type(file_data[1]))
    lines.append('')
    lines.append(file_data[2])
    lines.append('--' + boundary + '--')
    lines.append('')
    body = crlf.join(lines)
    content_type = 'multipart/form-data; boundary=%s' % boundary
  
    return content_type, body

def get_content_type(filename):
    """Returns MIME type for the provided file name."""
    return mimetypes.guess_type(filename)[0] or 'application/octet-stream'

def get_image_links(page):
    """Extracts links to direct and thumbnail images from the ImageShack 
    upload result page."""
    
    direct_link_re = """Direct Link<span(.+?)value="(.+?)" """
    thumbnail_link_re = """<div class="main-title" style="margin-bottom:8px">Upload Successful <img src=.+?/></div>.+?<img.+?src="(.+?)" style="_float:left"/>"""
    # direct regex spans multiple lines, we need to use the re.DOTALL flag    
    match_direct = re.search(direct_link_re, page, re.DOTALL)
    if match_direct is None:
        raise NoMatchError('Could not extract direct link to image from the resulting page.')
    # thumbnail regex spans multiple lines, we need to use the re.DOTALL flag    
    match_thumbnail = re.search(thumbnail_link_re, page, re.DOTALL)
    if match_thumbnail is None:
        raise NoMatchError('Could not extract thumbnail link to image from the resulting page.')
    direct_link = match_direct.group(2)
    thumb_link = match_thumbnail.group(1)
    # check if thumbnail was created at all
    # for small images ImageShack doesn't create thumbnails
    # direct image link should be used as a thumbnail in that case
    if thumb_link == '/images/thumbnail.gif':
        thumb_link = direct_link
    
    return (direct_link, thumb_link)

def fetch_result_page(url):
    """Downloads upload results page and returns its contents."""
    # strip 'http://' from the url
    location = url[7:]
    # find host/path separator
    path_start = location.find('/')
    # open new HTTP connection
    conn = httplib.HTTPConnection(location[:path_start])
    conn.request('GET', location[path_start:])
    # fetch page
    upload_result = conn.getresponse().read()
    conn.close()
    return upload_result

def upload_file_to_imageshack(file_name, file_contents, remove_thumbnail_bar = False):
    """Uploads given file to ImageShack.
    Parameters:
    file_name -- name of the uploaded file
    file_contents -- contents of the uploaded file
    remove_thumbnail_bar -- flag indicating whether the summary bar should 
                            be removed from the thumbnail image
    
    Returns: tuple with direct and thumbnail image links.
    """
    file_data = ('fileupload', file_name, file_contents)
    form_fields = BASIC_FORM_FIELDS
    if remove_thumbnail_bar:
        form_fields.append(REMOVE_THUMB_BAR_FIELD)
    
    content_type, form_body = encode_multipart_formdata(form_fields, file_data)
    headers = {
        'Content-Type' : content_type,
        'Content-Length' : str(len(form_body)),
        'Referer' : REFERER,
        'User-Agent' : USER_AGENT,
    }
    
    upload_response = send_form_with_file(HOST, UPLOAD_PATH, headers, form_body)
    # we assume that server should return 302 redirect here
    if upload_response.status != 302:
        raise UnexpectedServerCodeError(upload_response.status)
    # now we need to handle redirection
    result_location = upload_response.getheader('Location')
    upload_result = fetch_result_page(result_location)
    # return links to images
    return get_image_links(upload_result)

def write_links(links, failures, outputs):
    """Writes image links and to given file descriptors."""
    for link in links:
        for fp in outputs['direct_links']:
            print >> fp, link[IDX_DIRECT_LINK]
        for fp in outputs['thumbnail_links']:
            print >> fp, link[IDX_THUMBNAIL_LINK]
    for f in failures:
        for fp in outputs['failures']:
            print >> fp, f

def check_positive_option(option, opt_str, value, parser):
    """Used as a callback b OptionParser. Checks if given option is a positive number."""
    if value <= 0:
        raise OptionValueError('option %s: value should be a number greater than zero' % opt_str)
    else:
        # OK, set option value
        setattr(parser.values, option.dest, value)

def create_option_parser():
    """Creates and configures option parser for shackshag."""
    parser = OptionParser(usage = 'usage: %prog [options] <image files>')
    parser.add_option('-r', '--clean-thumbs', dest='clean_thumbs', 
                      action='store_true', default=False, 
                      help='remove size/resolution bar from thumbnails')
    parser.add_option('-s', '--stdout', dest='use_stdout', 
                      action='store_true', 
                      help='use standard output to write direct image links (default when no output files are specified)')
    parser.add_option('-v', '--verbose', dest='verbose', 
                      action='store_true', default=False,
                      help='be verbose, write additional information to standard output')
    parser.add_option('-d', '--direct', dest='direct_file',
                      help='write direct image links to DIRECT_FILE',
                      metavar='DIRECT_FILE')
    parser.add_option('-t', '--thumbnails', dest='thumbnails_file', 
                      help='write thumbnail links to THUMBNAILS_FILE',
                      metavar='THUMBNAILS_FILE')
    parser.add_option('-f', '--failures', dest='failures_file', 
                      help='write file names that failed to be uploaded to FAILURES_FILE (they are written to standard output by default)',
                      metavar='FAILURES_FILE')
    parser.add_option('-n', '--retries', dest='num_tries',
                      type='long', default=DEFAULT_NUM_TRIES,
                      action='callback', callback=check_positive_option,
                      help='try to upload file NUM_TRIES, default number retries is %d' % DEFAULT_NUM_TRIES,
                      metavar='NUM_TRIES')
    return parser 

def main():
    parser = create_option_parser()
    (options, args) = parser.parse_args()
    # check if we're not given the same output file for
    # different output types
    files_count = 0
    file_names = set()
    if options.direct_file is not None:
        files_count += 1
        file_names.add(options.direct_file)
    if options.thumbnails_file is not None:
        files_count += 1
        file_names.add(options.thumbnails_file)
    if options.failures_file is not None:
        files_count += 1
        file_names.add(options.failures_file)
    if files_count != len(file_names):
        parser.error("it's not possible to use the same file for different output types")
    # check if we have at least one file to upload
    if len(args) == 0:
        parser.error("no image files provided!")
    # set default output stream in case no output files are given
    if (not options.direct_file is not None and 
       not options.thumbnails_file and
       not options.failures_file):
        setattr(options, 'use_stdout', True)
    # upload files
    links = []
    failed_uploads = []
    import glob
    import os.path
    for file_name_mask in args:
        for file_name in glob.glob(file_name_mask):
            if not os.path.isfile(file_name):
                continue
            try:
                fp = open(file_name, 'rb')
            except IOError:
                print sys.stderr, "Failed to open file: %s, skipping!" % file_name
            else:
                try:
                    file_contents = fp.read()
                except:
                    print >> sys.stderr, ("Error when reading file: %s, skipping!" %
                          file_name)
                else:
                    try:
                        if options.verbose:
                            print "Attempting to upload file: %s" % file_name
                        tries = 0
                        while tries < options.num_tries:
                            tries += 1
                            try:
                                links.append(upload_file_to_imageshack(
                                             os.path.basename(file_name), file_contents,
                                             options.clean_thumbs))
                            except UnexpectedServerCodeError, err:
                                if options.verbose:
                                    print"Server returned unexpected response code (%s) when uploading file %s. Try %d of %d." % (str(err), os.path.basename(file_name), tries, options.num_tries)
                            else:
                                # upload was successful, get out of the loop
                                break
                        if tries == options.num_tries:
                            failed_uploads.append("Failed to upload: %s" % file_name)
                            print >> sys.stderr, ("Failed to upload file: %s. Tried %d times." % (file_name, tries))
                            
                    except Exception, err:
                        failed_uploads.append("Failed to upload: %s" % file_name)
                        print >> sys.stderr, ("Failed to upload file: %s. %s" % 
                              (file_name, str(err)))
                finally:
                    fp.close()
    # output streams dictionary
    outputs = {'direct_links': [], 'thumbnail_links': [], 'failures': []}
    # prepare output streams for direct links and failed uploads
    if options.use_stdout:
        # stdout should be used apart from files
        outputs['direct_links'].append(sys.stdout)
        outputs['failures'].append(sys.stdout)
    if options.direct_file:
        try:
            outputs['direct_links'].append(open(options.direct_file, 'w'))
        except IOError:
            print >> sys.stderr, ("Failed to open output file: %s" % 
                     options.direct_file)
            print >> sys.stderr, "Falling back to stdout!"
            if not options.use_stdout:
                outputs['direct_links'].append(sys.stdout)
    # prepare output streams for thumbnail links
    if options.thumbnails_file:
        try:
            outputs['thumbnail_links'].append(open(options.thumbnails_file, 'w'))
        except IOError, err:
            print >> sys.stderr, ("Failed to open output file: %s. %s" % 
                     (options.thumbnails_file, err.message))
            print >> sys.stderr, "Falling back to stdout!"
            outputs['thumbnail_links'].append(sys.stdout)
    # prepare output streams for failed upload
    if options.failures_file:
        try:
            outputs['failures'].append(open(options.failures_file, 'w'))
        except IOError, err:
            print >> sys.stderr, ("Failed to open output file: %s. %s" % 
                     (options.failures_file, err.message))
            print >> sys.stderr, "Falling back to stdout!"
            outputs['failures'].append(sys.stdout)
    try:
        write_links(links, failed_uploads, outputs)
    except Exception, err:
        print >> sys.stderr, ("Error writing image links to files! %s" % 
                 err.message)
    finally:
        for fp in outputs['direct_links'] + outputs['thumbnail_links'] + outputs['failures']:
            if fp != sys.stdout:
                fp.close()

if __name__ == '__main__':
    main()


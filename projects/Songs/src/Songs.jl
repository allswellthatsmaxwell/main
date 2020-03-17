module Songs

using AWSCore, AWSS3
using Base.Filesystem: dirname, mkdir, ispath

BUCKET_NAME = "maxwell-main"
LYRICS_ZIPNAME = "380000-lyrics-from-metro-lyrics.zip"
LOCAL_DATA_DIR = "data"
function download(; s3bucket = BUCKET_NAME, s3path = LYRICS_ZIPNAME,
                  outpath = "$(LOCAL_DATA_DIR)/$(LYRICS_ZIPNAME)")
    dir = dirname(outpath)
    if !ispath(dir) mkdir(dir) end
    
    aws = aws_config()    
    s3_get_file(aws, s3bucket, s3path, outpath)
end

download()

end

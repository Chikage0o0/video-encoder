# video-encoder
use vapoursynth and svt-av1 to encoder video in docker and control with a go program
```
docker run -d --name='video-encoder' -p '8888:8888/tcp' \
  -v '$(pwd)/videos':'/videos' \
  -v '$(pwd)/config':'/jupyter' \ 
  chikage/video-encoder:latest 
```
Now You can  open http://IP:8888 and visit jupyter,the token will show in the `docker logs  video-encoder`

And you can create a ipynb,this is some vapoursynth sample:
```
%load_ext yuuno
import fvsfunc as fvf
import mvsfunc as mvf
import havsfunc as haf
%%vspreview
video = core.lsmas.LWLibavSource(source)
video = fvf.Depth(video, 16)
video = haf.SMDegrain(video,tr=2,thSAD=300,RefineMotion=True,contrasharp=True,chroma=True,plane=0,prefilter=3)
#video = core.f3kdb.Deband(video,range=15,y=64,cb=64,cr=64,keep_tv_range=True,output_depth=16)
video = core.assrender.TextSub(video,sub,fontdir=fontsdir)
video = fvf.Depth(video, 10, dither_type='ordered')
video.set_output()
```

finally,you can use vspipe、svt-av1、ffmpeg to encoder the video
```
vspipe --y4m test.vpy - | SvtAv1EncApp -i stdin --input-depth 10 --preset 4 --rc 0 --crf 28 \
  --irefresh-type 2 --aq-mode 2 --lookahead -1 --scd 1 --keyint 240 --enable-tf 1 --enable-overlays 0 --enable-dlf 1 --enable-cdef 1 --enable-restoration 1 -b test.ivf
ffmpeg -i test.ivf  -i inputfile -map 0:v -map 1:a -map_chapters 1 -c:v copy \
  -c:a:0 libopus -filter:a aresample=48000:osf=s16:ocl=stereo:dither_method=triangular_hp -b:a:0 192k test.mp4
```

## TODO

- [ ] Automatic concurrent video encoding based on performance
- [ ] Monitor directories and automatically transcode according to presets
- [ ] Get rid of configuration files, web-based visual configuration


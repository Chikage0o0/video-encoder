# Video Encoder
集成VapourSynth、FFMPEG、Jupyter的视频压制Docker环境，添加了常用的VapourSynth插件以及Yuuno插件

Because my English and its bad, English documents welcome big brother to raise PR.

# How to Use

## 安装容器
推荐在Windows11和Linux环境中使用
### Windows
首先你需要做的是安装`Windows 2004`之后的版本，推荐直接安装Windows11（对终端的继承性更好）。
#### 安装WSL2
使用管理员打开Powershell，输入:
```powershell
wsl --install
```
这条命令将默认安装Ubuntu Lts，如果你想获得更详细的说明参考微软官方：[安装 WSL](https://docs.microsoft.com/zh-cn/windows/wsl/install)。
#### 安装Docker
下载[WindowsDocker](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)并安装。安装后可以在PowerShell中输入`docker -v`验证安装是否成功。

##### Docker加速
因为中国国内访问docker.io的速度不太理想，所以你可能需要使用[Netch](https://github.com/netchx/netch)来加速镜像的下载。

新增进程模式，将以下内容添加进入Netch即可加速Docker以及容器内的网络访问速度。

<details>
<summary>展开查看</summary>
<pre><code>
com\.docker\.cli\.exe
docker-compose-v1\.exe
docker-compose\.exe
docker-credential-desktop\.exe
docker-credential-ecr-login\.exe
docker-credential-wincred\.exe
docker\.exe
hub-tool\.exe
kubectl\.exe
docker-buildx\.exe
docker-compose\.exe
docker-sbom\.exe
docker-scan\.exe
com\.docker\.admin\.exe
com\.docker\.backend\.exe
com\.docker\.dev-envs\.exe
com\.docker\.diagnose\.exe
com\.docker\.extensions\.exe
com\.docker\.proxy\.exe
com\.docker\.wsl-distro-proxy\.exe
Docker desktop\.exe
dockerd\.exe
snyk\.exe
vpnkit-bridge\.exe
vpnkit\.exe
docker-buildx\.exe
docker-compose\.exe
docker-sbom\.exe
docker-scan\.exe
com\.docker\.cli\.exe
docker-compose-v1\.exe
docker-compose\.exe
docker-credential-desktop\.exe
docker-credential-ecr-login\.exe
docker-credential-wincred\.exe
docker\.exe
hub-tool\.exe
kubectl\.exe
winpty-agent\.exe
pagent\.exe
Docker Desktop\.exe
</code></pre>
</details>

#### 启动镜像
打开PowerShell输入
```powershell
docker run -d --name=video-encoder -p 8888:8888 -v  "${PWD}/videos:/videos" -v "${PWD}/config:/jupyter" chikage/video-encoder:latest
```
这将在你的当前目录下生成两个文件夹`videos`、`config`，`videos`用于存储待处理的视频，而`config`用于存储Jupyter运行时的配置文件


### Linux
对于Linux，直接使用一键脚本安装Docker即可，相信会用Linux的你肯定懂得如何加速下载的
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

输入以下命令
```bash
docker run -d $(id -u ${USER}):$(id -g ${USER}) --name=video-encoder -p 8888:8888 -v  $(pwd)/videos:/videos -v $(pwd)/config:/jupyter chikage/video-encoder:latest
```
如果处于某些原因，你不想用当前用户登录容器，您可以将`${USER}`替换成相应的用户名。

在容器内，如果想安装安装其他软件，可以输入
```
su
密码为：123456
```
即可登录`root`用户

## 使用容器


#### 打开Jupyter
如果没有任何异常，继续输入
```bash
docker logs video-encoder
````
如果没有任何意外，你将会看到
```
    To access the server, open this file in a browser:
        file:///jupyter/runtime/jpserver-1-open.html
    Or copy and paste one of these URLs:
        http://e2bff4fcaf08:8888/lab?token=71011ade4b7243caa2b7aea867572136c4370ebabbfe286b
     or http://127.0.0.1:8888/lab?token=71011ade4b7243caa2b7aea867572136c4370ebabbfe286b
```
这是我们访问[http://127.0.0.1:8888](http://127.0.0.1:8888),找到`Setup a Password`,填入`token=`后面的字符，例如本次的**Token**就是`71011ade4b7243caa2b7aea867572136c4370ebabbfe286b`，再输入密码，即可登录。

之后可以直接使用密码登录，而无需记忆Token。

#### 创建ipynb
首先你需要编写你的滤镜脚本

创建VS环境
```python
%load_ext yuuno
```
加载压制资源
```python
source="视频路径"
sub="字幕路径"
fontsdir="字体文件夹"
```
引用相关脚本
```python
import fvsfunc as fvf
import mvsfunc as mvf
import havsfunc as haf
```
对视频进行降噪去色带处理，一般来说，动漫的BD原盘都需要该处理。
```python
video = core.lsmas.LWLibavSource(source)
video = core.fmtc.bitdepth (video, bits=16)
video = core.nlm_ispc.NLMeans(video, d=1,a=2,h=1.2,channels="Y")
video = core.f3kdb.Deband(video,range=15,y=64,cb=64,cr=64,keep_tv_range=True,output_depth=16)
video = core.fmtc.bitdepth (video, bits=10,dmode=3)
```
添加字幕，如果不需要编码字幕进入视频，则不需要该环节
```python
video = core.assrender.TextSub(video,sub,fontdir=fontsdir)
```
最后输出即可
```python
%%vspreview
video.set_output()
```
运行下来，你将得到一个预览框，你可以根据预览内容调整Vapoursynth参数，对于更多用法可以参看[https://github.com/Morpheus1123/ZeroS-vapoursynth-template](https://github.com/Morpheus1123/ZeroS-vapoursynth-template)

#### 创建VPY
刚才创建的只是方便我们调试的脚本，调试完成后，我们就可以将参数写入生产环境以备压制。
刚才的参数写入成VPY应该为：
```python
import vapoursynth as vs
core = vs.core
core.num_threads = 24 #线程数
core.max_cache_size = 4000 #内存限制

source="视频路径"
sub="字幕路径"
fontsdir="字体文件夹"


import fvsfunc as fvf
import mvsfunc as mvf
import havsfunc as haf

video = core.lsmas.LWLibavSource(source)
video = core.fmtc.bitdepth (video, bits=16)
video = core.nlm_ispc.NLMeans(video, d=1,a=2,h=1.2,channels="Y")
video = core.f3kdb.Deband(video,range=15,y=64,cb=64,cr=64,keep_tv_range=True,output_depth=16)
video = core.fmtc.bitdepth (video, bits=10,dmode=3)

video = core.assrender.TextSub(video,sub,fontdir=fontsdir)
#输出
video.set_output()
```
没错，相比较之前的脚本，删去了`%load_ext yuuno`、`%%vspreview`，增加了前4行就可以了。

#### 开始制作视频
这里只介绍SVT-AV1的命令行，其他的请自行摸索，在Jupyter中新建终端输入：

几乎无损的压制命令
```bash
vspipe -c y4m test.vpy - | SvtAv1EncApp -i stdin --input-depth 10 --preset 4 --crf 20  --scm 2 --tune 0 --film-grain 8 -b tmp.ivf
ffmpeg -i tmp.ivf  -i 视频文件 -map 0:v -map 1:a:0 -map_chapters 1 -c:v copy -c:a copy   output.mkv
```
在这里vpy文件名为`test.vpy`，输出视频文件名为`output.mkv`,命令中的**视频文件**则为视频源文件

高压缩的命令为
```
vspipe -c y4m test.vpy - | SvtAv1EncApp -i stdin --input-depth 10 --preset 4 --crf 30  --scm 2 --tune 0 --film-grain 8 -b tmp.ivf
ffmpeg -i tmp.ivf  -i 视频文件 -map 0:v -map 1:a:0 -map_chapters 1 -c:v copy   -c:a:0 libopus -b:a 160K   output.mkv
```

目前Vapoursynth已经可以接受音频的输入与输出，首先需要修改脚本中输入输出：
```
video = core.ffms2.Source(source)
audio = core.bas.Source(source, track=-1)

video.set_output(0)
audio.set_output(1)
```
然后新建终端，输入命令
```
vspipe -o 0 -c y4m test.vpy - | SvtAv1EncApp -i stdin --input-depth 10 --preset 4 --crf 30  --scm 2 --tune 0 --film-grain 8 -b tmp.ivf
vspipe -o 1 -c wav test.vpy - | opusenc --bitrate 160 --downmix-stereo - tmp.opus
ffmpeg -i tmp.ivf  -i tmp.opus -map 0:v -map 1:a:0 -c:v copy   -c:a copy  output.mkv
```

HDR视频的压制需要在SVT-AV1中添加更多参数，可以参考[官方文档](https://github.com/AOMediaCodec/SVT-AV1/blob/master/Docs/CommonQuestions.md#hdr-and-sdr-video)

## 更新容器
```
docker rm -f video-encoder
docker pull chikage/video-encoder:latest
```
接下来重新创建容器即可

## 进阶使用
相信看到这里，你已经明白的基本的使用方式，这里将传授给你一些高阶使用技巧。
### GPU加速
VapourSynth很多滤镜需要大量的计算，例如NL-Mean降噪算法使用CPU进行运算的话就需要占用大量的运算资源，这时候如果使用GPU就可以大幅度减轻CPU的压力。对于GPU的使用，Nvidia与INTEL和AMD的方法不同，而且Windows下也与Linux系统下不同。

#### Windows
很抱歉，Windows下目前仅支持**Nvidia**的**CUDA**加速，其他一律不可用，你可以在Docker命令中加入`--gpu all`开启Nvidia显卡加速。Cuda目前可以让VapourSynth使用例如[Real-CUNET](https://github.com/bilibili/ailab/tree/main/Real-CUGAN/VapourSynth)、[RIFE](https://github.com/HolyWu/vs-rife)等AI算法提高时评质量。

#### Linux
Linux下的选项相比较Windows就丰富多了。

||CUDA|OPENCL|VULKAN|
|----|----|----|----|
|Nvidia|√|√|×|
|INTEL|×|√|√|
|AMD|×|√|√|

不过不要对INTEL的vulkan抱任何希望，毕竟核显能有多少算力。

##### Nvidia
首先你需要安装Nvidia闭源驱动以及`Nvidia Container Toolkit`,接下来和Windows一样，添加`--gpu all`至docker启动命令，这时启动的Docker已经可以使用CUDA了，而**OPENCL**还需要一些其他操作。
在Jupyter里新建一个终端，并切换到root用户
```
pacman -Syy
pacman -S ocl-icd clinfo
mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
```
这时如果输入`clinfo`有多行输入，即代表你可以使用OPENCL的API了。

##### INTEL与AMD
为何这两家一起说呢，其实这两家使用方式基本一样。
首先你需要在docker运行命令里加入`--devices /dev/dri`，接下来在Jupyter里新建一个终端，并切换到root用户

INTEL
```
pacman -Syy
pacman -S intel-compute-runtime ocl-icd clinfo vulkan-intel vulkan-tools vulkan-icd-loader
clinfo      #验证opencl
vulkaninfo  #验证vulkan
```

AMD
```
pacman -Syy
pacman -S opencl-mesa ocl-icd clinfo vulkan-radeon vulkan-tools vulkan-icd-loader
clinfo      #验证opencl
vulkaninfo  #验证vulkan
```

opencl的用处大家都知道，那vulkan有啥用呢？

其实上面的AI算法基本上都有NCNN的实现，AMD显卡调用VULKAN API进行运算效率也是非常高的哦。

## TODO

- [ ] Automatic concurrent video encoding based on performance
- [ ] Monitor directories and automatically transcode according to presets
- [ ] Get rid of configuration files, web-based visual configuration

## END
感谢你看到这里，如果感觉对你有所帮助，不妨给我点个Star。


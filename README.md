# nginx-media-server
Docker image for RTMP/HLS/DASH server running on nginx-1.18.0 with nginx-rtmp-module-1.2.1

## Introduction
This docker image can be used to create an RTMP server to serv HLS, DASH and RTMP at a time with nginx and nginx-rtmp-module, built from the current latest sources of the NGINX stable branch. 

* **docker hub**: <https://hub.docker.com/r/woonizzooni/nginx-media-server>

## Dockefile links
- [woonizzooni/nginx-media-server:latest](https://github.com/woonizzooni/nginx-media-server/blob/main/Dockerfile)


## Reference Links
- [nginx](https://nginx.org/)
- [docker-nginx](https://github.com/nginxinc/docker-nginx)
- [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)
- [Directives](https://github.com/arut/nginx-rtmp-module/wiki/Directives)


## Configurations
This image exposes port 1935 for RTMP steams and 8080 for HLS and DASH streams. 

A fragment(HLS & DASH) length is set to 2 seconds, and the total length is set to 16 seconds in the manifest (m3u8/mpd).

Refer to /etc/nginx/nginx.conf for details.

## How to use

### Running NGINX-MEDIA-SERVER
* Run the following:
```bash
docker run -d -p 1935:1935 -p 8080:8080 --name nginx-media-server woonizzooni/nginx-media-server:latest
```

### Publishing Stream with
* FFMPEG

  * Download and Install 
    - [download](https://ffmpeg.org/download.html)
    - [compilation](https://trac.ffmpeg.org/wiki/CompilationGuide)
    - [kor-macos-ffmpeg-install](https://woonizzooni.tistory.com/entry/macOS-ffmpeg-설치)
    - [kor-win-vs-compile](https://woonizzooni.tistory.com/entry/FFmpeg-Visual-Studio-2019-컴파일-1)
  * Capture Desktop or Camera and Publish RTMP stream
    - [capture desktop](https://trac.ffmpeg.org/wiki/Capture/Desktop)
    - [kor-macos-capture-desktop-rtmp](https://woonizzooni.tistory.com/entry/macos-ffmpeg으로-화면캡처capture-desktop해서-rtmp송출)
    ```bash
    ffmpeg -f avfoundation -video_device_index 1 -audio_device_index 0 -i "default" \
      -c:v libx264 -deinterlace -r 24 -s 1280x720 -b:v 1200k \
        -minrate 1200k -maxrate 1200k -bufsize 1200k  -pix_fmt yuv420p \
        -profile:v baseline -x264-params keyint=48:keyint_min=24:scenecut=0:bframes=0 \
      -c:a libfdk_aac -b:a 128k -ar 44100
      -f flv rtmp://localhost:1935/live/test
    ```
    - [kor-win-capture-desktop-rtmp](https://woonizzooni.tistory.com/entry/Windows-ffmpeg으로-화면캡처capture-desktop해서-rtmp송출)
    ```bash
    ffmpeg -f gdigrab -i desktop \
      -c:v libx264 -deinterlace -r 24 -s 1280x720 \
        -b:v 2400k -minrate 2400k -maxrate 2400k -bufsize 2400k -pix_fmt yuv420p \
        -profile:v baseline -x264-params keyint=48:keyint_min=24:scenecut=0:bframes=0 \
      -f flv rtmp://localhost:1935/live/test
    ```
  * Publish RTMP stream with MP4
    - [kor-mp4-rtmp](https://woonizzooni.tistory.com/entry/ffmpeg과-동영상-파일로-rtmp-송출하기)
    ```bash
    ffmpeg -nostdin -re -stream_loop -1 -i ~/Movies/sample_h264_aac.mp4 \
      -c:v copy -c:a copy \
      -f flv "rtmp://localhost:1935/live/test"
    ```

* OBS Studio

  * Download and Install
   - [download](https://obsproject.com/ko/download) 
  * Set the stream settings as follows:
    ```settings
    Settings > Stream
        Service: Custom...
        Server: rtmp://localhost:1935/live
        Stream Key: test
    ```
  * Click 'Start Streaming' 


### Playing/Watching Stream with 
* PlaybackURL
  ```playbackURL
  HLS       : http://localhost:8080/hls/test/index.m3u8
  MPEG-DASH : http://localhost:8080/dash/test/index.mpd
  ```

* FFPROBE
  ```bash
  ffplay http://localhost:8080/hls/test/index.m3u8
  ```

* VLC or Universal MediaPlayer that supported HLS and MPEG-DASH

  * List of Players
    - [vlc/download](https://www.videolan.org)
    - [iina-macos-only](https://iina.io/)
    - [chrome hls plugin](https://chrome.google.com/webstore/detail/native-hls-playback/emnphkkblegpebimobpbekeedfgemhof)
    - [dash reference client](https://reference.dashif.org/dash.js/)

  * Open network stream menu and enter the HLS playback url (ex. https://localhost:8080/hls/test/index.m3u8)


## Deploying a Containerized nginx-media-server application on Kubernetes

* Prerequisite : kubernetes cluster
  - [kor-create-local-cluster](https://woonizzooni.tistory.com/entry/로컬에-Kubernetes-실행-환경-만들기)
  - [kubectl/minikube](https://kubernetes.io/ko/docs/tasks/tools/)

* Creating
  ```bash
  $ kubectl apply -f ./k8s/namespace.yaml
  $ kubectl apply -f ./k8s/service.yaml
  $ kubectl apply -f ./k8s/deployment.yaml
  ```

* Deleting
  ```bash
  $ kubectl delete -f ./k8s/deployment.yaml
  $ kubectl delete -f ./k8s/service.yaml
  $ kubectl delete -f ./k8s/namespace.yaml
  ```

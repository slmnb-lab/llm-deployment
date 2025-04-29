# llm-deployment
镜像打包与部署，支持ollama，vllm，lms等方式，自动部署到suanli.cn

## 打包Ollama镜像

- clone项目

```bash
git clone https://github.com/slmnb-lab/llm-deployment.git
```

- 修改 `ollama` 目录下的 `ollama_pull.sh` 文件中的模型名称。
> 模型列表参考 [Ollama官网](https://ollama.com/library)

```bash
#!/bin/bash
ollama serve &
sleep 15
ollama pull qwen3:30b-a3b  # 替换成你需要的模型

```

 - 修改  `ollama` 目录下的 `compose.yml` 文件中的模型名称。
 > 开始之前需要在suanli.cn中创建一个镜像仓库，镜像仓库名称为 `qwq`，镜像标签为 `30b-a3b`。访问这里 [初始化镜像仓库](https://console.suanli.cn/serverless/image)

```yaml

services:
  qwq:
    image: harbor.suanleme.cn/xuwenzheng/qwen3:30b-a3b  ## 这里是suanli.cn中创建的镜像仓库地址  harbor.suanleme.cn 是仓库地址 xuwenzheng 是账号名称 qwen3 是镜像名称 30b-a3b 是镜像标签
    build: .
    labels:
      - suanleme_0.http.port=11434          # 这里是ollama运行的端口，不要修改
      - suanleme_0.http.prefix=qwen332b     # 这里是发布到的suanli.cn的回传域名
    restart: unless-stopped
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    ports:
      - "11434:11434"                        # 这里是ollama运行的端口，不要修改

```

- 运行打包脚本

```bash
docker compose build
```

## 镜像上传
将打包的镜像上传到suanleme.cn

- 登录镜像仓库
```bash
docker login harbor.suanleme.cn --username=xuwenzheng

## 输入密码
*******

```

- 上传镜像
```bash
## 为新生成的镜像打上标签
docker tag harbor.suanleme.cn/xuwenzheng/qwen3:30b-a3b harbor.suanleme.cn/xuwenzheng/qwen3:30b-a3b

## 上传镜像
docker push harbor.suanleme.cn/xuwenzheng/qwen3:30b-a3b
```


## 部署服务
点击这里 [部署服务](https://console.suanli.cn/serverless/create/idc) ，登录后根据页面提示进行部署。
<<<<<<< HEAD



=======
>>>>>>> refs/remotes/origin/main

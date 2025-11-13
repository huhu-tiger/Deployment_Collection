#!/bin/bash
set -eu

comfyui_dir=/root/ComfyUI
comfyui_customnodes_dir=/root/ComfyUI/custom_nodes
pip_source=https://pypi.tuna.tsinghua.edu.cn/simple


echo "[INFO] Current Role=${Role-}"

echo "[INFO] Current PYTHONPATH_CUSTOM_PATH=${PYTHONPATH_CUSTOM_PATH-}"

# 取消代理
disable_proxy() {
    _OLD_HTTP_PROXY="${HTTP_PROXY-}"
    _OLD_HTTPS_PROXY="${HTTPS_PROXY-}"
    _OLD_NO_PROXY="${NO_PROXY-}"
    unset HTTP_PROXY HTTPS_PROXY NO_PROXY
}

# 还原代理
restore_proxy() {
    if [ -n "${_OLD_HTTP_PROXY-}" ]; then
        export HTTP_PROXY="$_OLD_HTTP_PROXY"
    else
        unset HTTP_PROXY
    fi
    if [ -n "${_OLD_HTTPS_PROXY-}" ]; then
        export HTTPS_PROXY="$_OLD_HTTPS_PROXY"
    else
        unset HTTPS_PROXY
    fi
    if [ -n "${_OLD_NO_PROXY-}" ]; then
        export NO_PROXY="$_OLD_NO_PROXY"
    else
        unset NO_PROXY
    fi
}

# 封装：在无代理环境下执行 pip 安装并自动还原代理
install_requirements_without_proxy() {
    disable_proxy
    pip install -r /root/ComfyUI/vnet/pip.txt -i $pip_source -t $PYTHONPATH_CUSTOM_PATH
    restore_proxy
}

install_custom_nodes() {
    # ComfyUI-QwenVL
    pushd $comfyui_customnodes_dir
    if [ -d "ComfyUI-QwenVL" ]; then
        echo "[INFO] ComfyUI-QwenVL 已存在，跳过安装。"
        popd
        return 0
    fi
    git clone https://github.com/1038lab/ComfyUI-QwenVL.git
    cd ComfyUI-QwenVL
    disable_proxy
    pip install \-r requirements.txt -i $pip_source -t  $PYTHONPATH_CUSTOM_PATH
    restore_proxy
    popd

}

# 只在第一个容器中起作用
if [ "${Role-}" = "master" ] ; then
    if [ ! -d "/root/ComfyUI/vnet" ] && [ -f "/root/extends/server.py" ] ; then
        echo "[INFO] Running pre-start script."
        cp -r /root/extends/vnet /root/ComfyUI/vnet
        chown -R 1000:1000 /root/ComfyUI/vnet
        chmod -R 755 /root/ComfyUI/vnet
        mv /root/ComfyUI/server.py /root/ComfyUI/server.py.bak
        cp -f /root/extends/server.py /root/ComfyUI/server.py
        install_requirements_without_proxy
        install_custom_nodes
    else
        install_requirements_without_proxy
        install_custom_nodes
    fi

fi
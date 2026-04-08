
SCRIPT_MY_OV_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${SCRIPT_MY_OV_DIR}

source ./python-env/bin/activate

USE_NIGHT_OV="0" # download from nightly build.

if [ $USE_NIGHT_OV = "1" ]; then
    echo "-------------- USE_NIGHTLY_OV"
    OS_VERSION=$(lsb_release -rs)
    if [ "$OS_VERSION" = "22.04" ]; then
        source ./openvino_toolkit_ubuntu22_2025.4.0.20398.8fdad55727d_x86_64/setupvars.sh
    elif [ "$OS_VERSION" = "24.04" ]; then
        source ./openvino_toolkit_ubuntu24_2025.4.0.20398.8fdad55727d_x86_64/setupvars.sh
    elif [ "$OS_VERSION" = "24.10" ]; then
        source ./openvino_toolkit_ubuntu24_2025.4.0.20398.8fdad55727d_x86_64/setupvars.sh
    else
        echo "Error: Can't support version of Ubuntu: $OS_VERSION"
    fi
else
    echo "-------------- Use my build OV"
    source ./openvino/build/install/setupvars.sh
    export OV_PATH=$SCRIPT_MY_OV_DIR/openvino
    export OV_PATH_BUILD=$OV_PATH/build

    # source ../openvino-new-arch/openvino/build/install/setupvars.sh
    # export OV_PATH=$SCRIPT_MY_OV_DIR/../openvino-new-arch/openvino/build
fi


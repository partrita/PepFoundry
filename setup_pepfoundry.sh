#!/bin/bash
set -e
set -o pipefail

ENV_NAME="default"

echo "========================================================"
echo "          PepFoundry Environment Setup (Pixi)           "
echo "========================================================"

# 1. Check if pixi is installed
if ! command -v pixi &> /dev/null; then
    echo "[INFO] Pixi is not found on PATH."
    echo "[INFO] Installing Pixi locally for current user..."
    curl -fsSL https://pixi.sh/install.sh | bash
    export PATH="$HOME/.pixi/bin:$PATH"
    if ! command -v pixi &> /dev/null; then
        echo "[ERROR] Pixi installation failed or not found in PATH."
        exit 1
    fi
fi

echo "[INFO] Pixi found: $(pixi --version)"

# 2. Check GPU / CUDA availability or environment override
if [[ -n "${CUDA_BUILD:-}" ]]; then
    echo "[INFO] Using user-defined build: $CUDA_BUILD"
    case $CUDA_BUILD in
        cuda|cu121|gpu)
            ENV_NAME="cuda"
            ;;
        cpu)
            ENV_NAME="cpu"
            ;;
        *)
            echo "[WARNING] Unknown CUDA_BUILD=$CUDA_BUILD. Falling back to default."
            ;;
    esac
elif command -v nvidia-smi &> /dev/null; then
    echo "[INFO] NVIDIA GPU detected via nvidia-smi."
    ENV_NAME="cuda"
else
    echo "[INFO] No NVIDIA GPU detected. Using CPU environment."
    ENV_NAME="cpu"
fi

echo "[INFO] Selected Pixi environment: '$ENV_NAME'"

# 3. Install environment dependencies locally in project (.pixi)
echo "[INFO] Installing dependencies via Pixi..."
pixi install -e "$ENV_NAME"

# 4. Verify installation
echo "[INFO] Verifying PepFoundry installation..."
pixi run -e "$ENV_NAME" python -c 'import pepfoundry; from pepfoundry.interface import PepFoundry; pf = PepFoundry(); print("✓ PepFoundry successfully initialized!")'

echo ""
echo "========================================================"
echo "[INFO] Setup completed successfully!"
echo "       No global or system packages were modified."
echo "       All dependencies are isolated in .pixi/"
echo ""
echo "Quick start:"
echo "  1) Run scripts directly:  pixi run python your_script.py"
echo "  2) Activate shell:        pixi shell -e $ENV_NAME"
echo "  3) Start Jupyter:         pixi run jupyter lab (or notebook)"
echo "========================================================"

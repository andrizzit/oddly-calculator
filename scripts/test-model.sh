#!/bin/bash
# Runs real application coordination code on macOS. Does not replace iOS UI tests.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Model checks require macOS because the shared coordinator imports SwiftUI." >&2
  exit 1
fi
model_qa_dir="$PWD/build/model-qa"
mkdir -p "$model_qa_dir/modules" "$model_qa_dir/cache"
swiftc -parse-as-library -swift-version 6 -emit-library -emit-module -module-name CalculatorCore \
  -module-cache-path "$model_qa_dir/cache" \
  -emit-module-path "$model_qa_dir/modules/CalculatorCore.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libCalculatorCore.dylib \
  Sources/CalculatorCore/*.swift -o "$model_qa_dir/libCalculatorCore.dylib"
swiftc -parse-as-library -swift-version 5 -I "$model_qa_dir/modules" \
  -module-cache-path "$model_qa_dir/cache" -L "$model_qa_dir" -lCalculatorCore \
  -Xlinker -rpath -Xlinker @executable_path \
  Oddly/CalculatorViewModel.swift scripts/check-model.swift -o "$model_qa_dir/check-model"
"$model_qa_dir/check-model"

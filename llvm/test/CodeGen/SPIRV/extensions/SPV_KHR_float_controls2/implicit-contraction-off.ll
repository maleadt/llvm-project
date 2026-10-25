; With SPV_KHR_float_controls2, the ContractionOff that kernels get by default
; is replaced by an FPFastMathDefault for every floating-point type, which
; requires the FloatControls2 capability and the extension even when no
; instruction is decorated with FPFastMathMode.

; RUN: rm -rf %t && split-file %s %t

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/strict.ll -o - | FileCheck %s --check-prefix=STRICT --implicit-check-not=FPFastMathMode --implicit-check-not=ContractionOff
; RUN: %if spirv-tools %{ llc -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/strict.ll -o - -filetype=obj | spirv-val %}

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/types.ll -o - | FileCheck %s --check-prefix=TYPES --implicit-check-not=FPFastMathMode
; RUN: %if spirv-tools %{ llc -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/types.ll -o - -filetype=obj | spirv-val %}

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/contract.ll -o - | FileCheck %s --check-prefix=CONTRACT
; RUN: %if spirv-tools %{ llc -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/contract.ll -o - -filetype=obj | spirv-val %}

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/integer.ll -o - | FileCheck %s --check-prefix=NONE --implicit-check-not=FloatControls2 --implicit-check-not=FPFastMathDefault --implicit-check-not=ContractionOff
; RUN: %if spirv-tools %{ llc -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/integer.ll -o - -filetype=obj | spirv-val %}

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/fp-contract.ll -o - | FileCheck %s --check-prefix=NONE --implicit-check-not=FloatControls2 --implicit-check-not=FPFastMathDefault --implicit-check-not=ContractionOff
; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 --spirv-fp-contract=fast %t/strict.ll -o - | FileCheck %s --check-prefix=NONE --implicit-check-not=FloatControls2 --implicit-check-not=FPFastMathDefault --implicit-check-not=ContractionOff

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/no-entry.ll -o - | FileCheck %s --check-prefix=NOENTRY --implicit-check-not=FloatControls2 --implicit-check-not=FPFastMathDefault --implicit-check-not=ContractionOff
; RUN: %if spirv-tools %{ llc -O0 -mtriple=spirv64-unknown-unknown --spirv-ext=+SPV_KHR_float_controls2 %t/no-entry.ll -o - -filetype=obj | spirv-val %}

; RUN: llc -verify-machineinstrs -O0 -mtriple=spirv64-unknown-unknown %t/strict.ll -o - | FileCheck %s --check-prefix=NOEXT --implicit-check-not=FloatControls2 --implicit-check-not=FPFastMathDefault

; STRICT-DAG: OpCapability FloatControls2
; STRICT-DAG: OpExtension "SPV_KHR_float_controls2"
; STRICT-DAG: OpEntryPoint Kernel %[[#ENTRY:]] "k"
; STRICT-DAG: OpExecutionModeId %[[#ENTRY]] FPFastMathDefault %[[#FLOAT:]] %[[#ZERO:]]
; STRICT-DAG: %[[#FLOAT]] = OpTypeFloat 32
; STRICT-DAG: %[[#ZERO]] = OpConstantNull %[[#]]

; TYPES-DAG: OpCapability FloatControls2
; TYPES-DAG: OpExtension "SPV_KHR_float_controls2"
; TYPES-DAG: OpExecutionModeId %[[#ENTRY:]] FPFastMathDefault %[[#HALF:]] %[[#ZERO:]]
; TYPES-DAG: OpExecutionModeId %[[#ENTRY]] FPFastMathDefault %[[#FLOAT:]] %[[#ZERO]]
; TYPES-DAG: OpExecutionModeId %[[#ENTRY]] FPFastMathDefault %[[#DOUBLE:]] %[[#ZERO]]
; TYPES-DAG: %[[#HALF]] = OpTypeFloat 16
; TYPES-DAG: %[[#FLOAT]] = OpTypeFloat 32
; TYPES-DAG: %[[#DOUBLE]] = OpTypeFloat 64

; CONTRACT-DAG: OpCapability FloatControls2
; CONTRACT-DAG: OpExtension "SPV_KHR_float_controls2"
; CONTRACT-DAG: OpExecutionModeId %[[#]] FPFastMathDefault %[[#]] %[[#]]
; CONTRACT-DAG: OpDecorate %[[#MUL:]] FPFastMathMode AllowContract
; CONTRACT-DAG: OpDecorate %[[#ADD:]] FPFastMathMode AllowContract
; CONTRACT-NOT: FPFastMathMode
; CONTRACT: %[[#MUL]] = OpFMul
; CONTRACT: %[[#ADD]] = OpFAdd
; CONTRACT: OpFMul

; NONE: OpEntryPoint Kernel

; NOENTRY: OpFunction

; NOEXT: OpExecutionMode %[[#]] ContractionOff

;--- strict.ll
define spir_kernel void @k(ptr addrspace(1) %p, float %x) {
  %y = fmul float %x, 2.0
  store float %y, ptr addrspace(1) %p
  ret void
}

;--- types.ll
define spir_kernel void @k(ptr addrspace(1) %p, half %h, <4 x float> %v,
                           double %d) {
  store i32 1, ptr addrspace(1) %p
  ret void
}

;--- contract.ll
define spir_kernel void @k(ptr addrspace(1) %p, float %x, float %y) {
  %a = load float, ptr addrspace(1) %p
  %m = fmul contract float %x, %y
  %r = fadd contract float %m, %a
  %s = fmul float %r, %x
  store float %s, ptr addrspace(1) %p
  ret void
}

;--- integer.ll
define spir_kernel void @k(ptr addrspace(1) %p, i32 %x) {
  %y = mul i32 %x, 2
  store i32 %y, ptr addrspace(1) %p
  ret void
}

;--- fp-contract.ll
define spir_kernel void @k(ptr addrspace(1) %p, float %x) {
  %y = fmul float %x, 2.0
  store float %y, ptr addrspace(1) %p
  ret void
}

!opencl.enable.FP_CONTRACT = !{}

;--- no-entry.ll
define spir_func float @f(float %x) {
  %y = fmul float %x, 2.0
  ret float %y
}

add_llvm_library(LLVMTransformUtils
  AddrModeMatcher.cpp
  BasicBlockUtils.cpp
  BasicInliner.cpp
  BreakCriticalEdges.cpp
  BuildLibCalls.cpp
  CloneFunction.cpp
  CloneModule.cpp
  CmpInstAnalysis.cpp
  CodeExtractor.cpp
  DemoteRegToStack.cpp
  InlineFunction.cpp
  InstructionNamer.cpp
  LCSSA.cpp
  Local.cpp
  LoopSimplify.cpp
  LoopUnroll.cpp
  LoopUnrollRuntime.cpp
  LowerExpectIntrinsic.cpp
  LowerInvoke.cpp
  LowerSwitch.cpp
  Mem2Reg.cpp
  ModuleUtils.cpp
  PromoteMemoryToRegister.cpp
  SSAUpdater.cpp
  SimplifyCFG.cpp
  SimplifyIndVar.cpp
  SimplifyInstructions.cpp
  UnifyFunctionExitNodes.cpp
  Utils.cpp
  ValueMapper.cpp
  )

; RUN: opt -basicaa -lint -disable-output < %s |& FileCheck %s
target datalayout = "e-p:64:64:64"

declare fastcc void @bar()
declare void @llvm.stackrestore(i8*)
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture, i64, i32, i1) nounwind
declare void @has_sret(i8* sret %p)
declare void @has_noaliases(i32* noalias %p, i32* %q)
declare void @one_arg(i32)

@CG = constant i32 7

define i32 @foo() noreturn {
; CHECK: Caller and callee calling convention differ
  call void @bar()
; CHECK: Null pointer dereference
  store i32 0, i32* null
; CHECK: Null pointer dereference
  %t = load i32* null
; CHECK: Undef pointer dereference
  store i32 0, i32* undef
; CHECK: Undef pointer dereference
  %u = load i32* undef
; CHECK: All-ones pointer dereference
  store i32 0, i32* inttoptr (i64 -1 to i32*)
; CHECK: Address one pointer dereference
  store i32 0, i32* inttoptr (i64 1 to i32*)
; CHECK: Memory reference address is misaligned
  %x = inttoptr i32 1 to i32*
  load i32* %x, align 4
; CHECK: Division by zero
  %sd = sdiv i32 2, 0
; CHECK: Division by zero
  %ud = udiv i32 2, 0
; CHECK: Division by zero
  %sr = srem i32 2, 0
; CHECK: Division by zero
  %ur = urem i32 2, 0
; CHECK: extractelement index out of range
  %ee = extractelement <4 x i32> zeroinitializer, i32 4
; CHECK: insertelement index out of range
  %ie = insertelement <4 x i32> zeroinitializer, i32 0, i32 4
; CHECK: Shift count out of range
  %r = lshr i32 0, 32
; CHECK: Shift count out of range
  %q = ashr i32 0, 32
; CHECK: Shift count out of range
  %l = shl i32 0, 32
; CHECK: xor(undef, undef)
  %xx = xor i32 undef, undef
; CHECK: sub(undef, undef)
  %xs = sub i32 undef, undef

; CHECK: Write to read-only memory
  store i32 8, i32* @CG
; CHECK: Write to text section
  store i32 8, i32* bitcast (i32()* @foo to i32*)
; CHECK: Load from block address
  %lb = load i32* bitcast (i8* blockaddress(@foo, %next) to i32*)
; CHECK: Call to block address
  call void()* bitcast (i8* blockaddress(@foo, %next) to void()*)()
; CHECK: Undefined behavior: Null pointer dereference
  call void @llvm.stackrestore(i8* null)
; CHECK: Undefined behavior: Null pointer dereference
  call void @has_sret(i8* null)
; CHECK: Unusual: noalias argument aliases another argument
  call void @has_noaliases(i32* @CG, i32* @CG)
; CHECK: Call argument count mismatches callee argument count
  call void (i32, i32)* bitcast (void (i32)* @one_arg to void (i32, i32)*)(i32 0, i32 0)
; CHECK: Call argument count mismatches callee argument count
  call void ()* bitcast (void (i32)* @one_arg to void ()*)()
; CHECK: Call argument type mismatches callee parameter type
  call void (float)* bitcast (void (i32)* @one_arg to void (float)*)(float 0.0)

; CHECK: Write to read-only memory
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* bitcast (i32* @CG to i8*), i8* bitcast (i32* @CG to i8*), i64 1, i32 1, i1 0)

  br label %next

next:
; CHECK: Static alloca outside of entry block
  %a = alloca i32
; CHECK: Return statement in function with noreturn attribute
  ret i32 0

foo:
  %z = add i32 0, 0
; CHECK: unreachable immediately preceded by instruction without side effects
  unreachable
}

; CHECK: Unnamed function with non-local linkage
define void @0() nounwind {
  ret void
}

; CHECK: va_start called in a non-varargs function
declare void @llvm.va_start(i8*)
define void @not_vararg(i8* %p) nounwind {
  call void @llvm.va_start(i8* %p)
  ret void
}

; CHECK: Undefined behavior: Branch to non-blockaddress
define void @use_indbr() {
  indirectbr i8* bitcast (i32()* @foo to i8*), [label %block]
block:
  unreachable
}

; CHECK: Undefined behavior: Call with "tail" keyword references alloca
declare void @tailcallee(i8*)
define void @use_tail(i8* %valist) {
  %t = alloca i8
  tail call void @tailcallee(i8* %t)
  ret void
}

; CHECK: Unusual: Returning alloca value
define i8* @return_local(i32 %n, i32 %m) {
  %t = alloca i8, i32 %n
  %s = getelementptr i8* %t, i32 %m
  ret i8* %s
}

; CHECK: Unusual: Returning alloca value
define i32* @return_obscured_local() {
entry:
  %retval = alloca i32*
  %x = alloca i32
  store i32* %x, i32** %retval
  br label %next
next:
  %t0 = load i32** %retval
  %t1 = insertvalue { i32, i32, i32* } zeroinitializer, i32* %t0, 2
  %t2 = extractvalue { i32, i32, i32* } %t1, 2
  br label %exit
exit:
  %t3 = phi i32* [ %t2, %next ]
  %t4 = bitcast i32* %t3 to i32*
  %t5 = ptrtoint i32* %t4 to i64
  %t6 = add i64 %t5, 0
  %t7 = inttoptr i64 %t6 to i32*
  ret i32* %t7
}

; CHECK: Undefined behavior: Undef pointer dereference
define i32* @self_reference() {
entry:
  unreachable
exit:
  %t3 = phi i32* [ %t4, %exit ]
  %t4 = bitcast i32* %t3 to i32*
  %x = load volatile i32* %t3
  br label %exit
}

; CHECK: Call return type mismatches callee return type
%struct = type { double, double }
declare i32 @nonstruct_callee() nounwind
define void @struct_caller() nounwind {
entry:
  call %struct bitcast (i32 ()* @foo to %struct ()*)()

  ; CHECK: Undefined behavior: indirectbr with no destinations
  indirectbr i8* null, []
}

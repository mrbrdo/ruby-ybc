/**
  @c variable
  @e Get value of local variable (pointed to by idx).
  @j idx で指定されたローカル変数をスタックに置く。
 */
#define YARV_GETLOCAL(var, sloc) \
	sloc = var.d

/**
  @c variable
  @e Set value of local variable (pointed to by idx) to val.
  @j idx で指定されたローカル変数を val に設定する。
 */
#define YARV_SETLOCAL(var, sloc) \
	var.d = sloc
	
/**
  @c put
  @e put string val. string will be copied.
  @j 文字列をコピーしてスタックにプッシュする。
 */
/*DEFINE_INSN
putstring
(VALUE str)
()
(VALUE val)
{
    val = rb_str_resurrect(str);
}*/
#define YARV_PUTSTRING(str, sloc) \
  sloc = rb_str_new2(str)
	
/**
  @c method/iterator
  @e obj.send(id, args..) # args.size => num
  @j メソッド呼び出しを行う。
  obj.send(id, args..) # args.size => num
    flag & VM_CALL_ARGS_SPLAT_BIT    != 0 -> splat last arg
    flag & VM_CALL_ARGS_BLOCKARG_BIT != 0 -> Proc as Block
    flag & VM_CALL_FCALL_BIT         != 0 -> FCALL ( func() )
    flag & VM_CALL_VCALL_BIT         != 0 -> VCALL ( func   )
    ...
 */
/*DEFINE_INSN
send
(ID op_id, rb_num_t op_argc, ISEQ blockiseq, rb_num_t op_flag, IC ic)
(...)
(VALUE val) // inc += - (int)(op_argc + ((op_flag & VM_CALL_ARGS_BLOCKARG_BIT) ? 1 : 0));
{
    const rb_method_entry_t *me;
    VALUE recv, klass;
    rb_block_t *blockptr = 0;
    VALUE flag = op_flag;
    int num = caller_setup_args(th, GET_CFP(), flag, (int)op_argc,
				(rb_iseq_t *)blockiseq, &blockptr);
    ID id = op_id;

    // get receiver
    recv = TOPN(num);
    klass = CLASS_OF(recv);
    me = vm_method_search(id, klass, ic);
    CALL_METHOD(num, blockptr, flag, id, me, recv);
}*/
/* basically the parameters are:
- Symbol name
- Fixnum how many arguments (they are on stack), also use TOPN instruction to get self after arguments are poped
- block InstructionSequence (YARV bytecode), ISEQ = rb_iseq_t*, from that it makes a rb_block_t
- flag is ORed flags for optimization in vm_call_method/vm_setup_method, like VM_CALL_FCALL_BIT, VM_CALL_VCALL_BIT
- IC ("inline method cache") is something for caching, used in vm_method_search, not using this for now

In C we can use (from README):

 VALUE rb_funcall(VALUE recv, ID mid, int narg, ...)

Invokes a method.  To retrieve mid from a method name, use rb_intern().

 VALUE rb_funcall2(VALUE recv, ID mid, int argc, VALUE *argv)

Invokes a method, passing arguments by an array of values.
There is also rb_funcall3 (not described in README).

To pass a block, it has to be a proc (rb_block_proc() will make proc from block given to C function), and then pass it as the last parameter to funcall.
*/
//(op_id, op_argc, blockiseq, op_flag, ic)
#define YARV_SEND(stack_top, stack_result, op_cstr, ...) \
  stack_result = rb_funcall(stack_result, rb_intern(op_cstr), __VA_ARGS__)

/**
  @c put
  @e put some object.
     i.e. Fixnum, true, false, nil, and so on.
  @j オブジェクト val をスタックにプッシュする。
     i.e. Fixnum, true, false, nil, and so on.
 */
/*DEFINE_INSN
putobject
(VALUE val)
()
(VALUE val)
{

}*/
#define YARV_PUTOBJECT(obj, sloc) \
	sloc = obj
/**
  @c put
  @e put self.
  @j スタックに self をプッシュする。
 */
/*DEFINE_INSN
putself
()
()
(VALUE val)
{
    val = GET_SELF();
}*/
// Self is passed as the first argument to C functions TODO
#define YARV_PUTSELF(sloc) \
	YARV_PUTOBJECT(self.d, sloc)
//	asm("push %0"::"m"(ruby_main_object))
/**
  @c variable
  @e Get value of block local variable (pointed to by idx and level).
     'level' indicates the nesting depth from the current block.
  @j level, idx で指定されたブロックローカル変数の値をスタックに置く。
     level はブロックのネストレベルで、何段上かを示す。
 */
/*DEFINE_INSN
getdynamic
(dindex_t idx, rb_num_t level)
()
(VALUE val)
{
    rb_num_t i;
    VALUE *ep = GET_EP();
    for (i = 0; i < level; i++) {
	ep = GET_PREV_EP(ep);
    }*/
#define YARV_GETDYNAMIC(idx, level, sloc) \
  YARV_PUTOBJECT(*(VALUE *)(NUM2LL(rb_iv_get(self.d, "@locals_ptr"))+(idx-1)*8), sloc);

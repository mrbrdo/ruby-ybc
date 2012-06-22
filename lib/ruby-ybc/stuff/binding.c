  
typedef struct rb_block_struct {
    VALUE self;     /* share with method frame if it's only block */
    VALUE *ep;      /* share with method frame if it's only block */
    void *iseq;
    VALUE proc;
} rb_block_t;

typedef struct {
    VALUE env;
    VALUE path;
    unsigned short first_lineno;
} rb_binding_t;

typedef struct {
    VALUE *env;
    int env_size;
    int local_size;
    VALUE prev_envval;    /* for GC mark */
    rb_block_t block;
} rb_env_t;


#define GetCoreDataFromValue(obj, type, ptr) do { \
    (ptr) = (type*)DATA_PTR(obj); \
} while (0)

#define GetEnvPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_env_t, (ptr))

#define GetBindingPtr(obj, ptr) \
  GetCoreDataFromValue((obj), rb_binding_t, (ptr))

VALUE bind_eval_c(VALUE self, VALUE bindval, const char *eval_str, const char *vfile, const int vline) {
  VALUE args[4];
  args[0] = rb_str_new2(eval_str); // eval string
  args[1] = bindval; // VALUE object with class Binding
  args[2] = rb_str_new2(vfile); // what you want ruby to think ruby file is
  args[3] = LL2NUM(vline); // what you want ruby to think line number is
  //rb_f_eval(4, args, self);
  return rb_funcall(self, rb_intern("eval"), 4, args[0], args[1], args[2], args[3]);
}

{
    int i;
    rb_env_t *env;
    rb_binding_t *bind;
    VALUE tmp;
    //VALUE toplevel_binding = rb_const_get(rb_cObject, rb_intern("TOPLEVEL_BINDING"));
    VALUE self_binding = rb_funcall(self.d, rb_intern("eval"), 1, rb_str_new2("binding")); // todo
    
    GetBindingPtr(toplevel_binding, bind);
    GetEnvPtr(bind->env, env);

    bind_eval_c(self.d,//rb_funcall(toplevel_binding, rb_intern("eval"), 1, rb_str_new2("self")),
      rb_funcall(self.d, rb_intern("eval"), 1, rb_str_new2("binding")),
      "puts self.class.to_s", "file.rb", 1);

    /*GetBindingPtr(toplevel_binding, bind);
    GetEnvPtr(bind->env, env);
    i = 3;
    tmp = rb_funcall(env->env[i], rb_intern("object_id"), 0);
    printf("%llx\n", NUM2LL(tmp));
    tmp = rb_funcall(env->env[i], rb_intern("class"), 0);
    tmp = rb_funcall(tmp, rb_intern("to_s"), 0);
    printf(StringValueCStr(tmp));*/
    //for (i=0; i<env->local_size; i++)
    //  printf("%d: %llx\n", i, NUM2LL(env->env[i]));
  }
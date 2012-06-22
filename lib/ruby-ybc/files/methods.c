#include "methods.h"
VALUE dispatch_table;
uintptr_t *func_ptr_cache;
int func_ptr_cache_size;

void clear_func_cache()
{
  memset(func_ptr_cache, 0, func_ptr_cache_size*sizeof(uintptr_t));
}

void resize_func_cache(int size)
{
  if (func_ptr_cache != 0) free(func_ptr_cache);
  func_ptr_cache_size = size;
  func_ptr_cache = malloc(func_ptr_cache_size*sizeof(uintptr_t));
  clear_func_cache();
}

uintptr_t find_method_ptr(VALUE klass, const char *name) __attribute__((noinline));
uintptr_t find_method_ptr(VALUE klass, const char *name) {
  VALUE name_sym = ID2SYM(rb_intern(name));
  VALUE result = Qnil;
  VALUE dpt;
  VALUE prevklass = Qnil;

  while (result == Qnil) {
    dpt = rb_hash_aref(dispatch_table, klass);
    if (dpt != Qnil) {
      result = rb_hash_aref(dpt, name_sym);
    }
    prevklass = klass;
    klass = CLASS_OF(klass);
    if (klass == prevklass) {
      printf("Error cannot find method %s\n", name); // TODO
      exit(1);
    }
  }

  return result; // else return exception handler (no such method)
}

uintptr_t method_dispatch_ptr(VALUE klass, const char *name, int cache_idx) {
  uintptr_t cache_item;
  if (cache_idx >= func_ptr_cache_size) // this check has some performance penalty, but not sure if can avoid it
    resize_func_cache(cache_idx + 100);
  cache_item = func_ptr_cache[cache_idx];

  if (cache_item != (uintptr_t)0)
    return cache_item;
  else {
    cache_item = find_method_ptr(klass, name);
    func_ptr_cache[cache_idx] = cache_item;
    return cache_item;
  }
}

void append_method_to_dispatch_table(VALUE klass, const char *name, uintptr_t func) {
  VALUE h = rb_hash_aref(dispatch_table, klass);
  if (h == Qnil) {
    h = rb_hash_new();
    rb_hash_aset(dispatch_table, klass, h);
  }
  rb_hash_aset(h, ID2SYM(rb_intern(name)), (VALUE)(func));
}

void InitMethods() {
  func_ptr_cache_size = 0;
  func_ptr_cache = 0; // TODO free memory? when/how?

  dispatch_table = rb_hash_new();
}
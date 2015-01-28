%{
#include <proton/rubyref.h>
  %}

%inline %{

  static VALUE mCproton;
  static VALUE cRubyRef;

  void *pn_rb2void(VALUE object) {
    return (void *)object;
  }

  VALUE pn_void2rb(void *object) {
    if (!object) {
      return Qnil;
    } else {
      return (VALUE)object;
    }
  }

  static void rubyref_mark(void *ptr) {
    // printf("inside:rubyref_mark\n");
    pn_rubyref_t *rubyref = (pn_rubyref_t *)ptr;
    VALUE rb_object = (VALUE)pn_rubyref_get_ruby_object(rubyref);

    if(rb_object != Qnil) {
      // printf("\tMarking a ruby object.\n");
      // printf("\tCalling rb_gc_mark on %ld\n", rb_object);
      rb_gc_mark(rb_object);
    } else {
      // printf("No ruby object to mark.\n");
    }
  }

  static void rubyref_free(void *ptr) {
    // printf("inside:rubyref_free\n");
    pn_rubyref_t *rubyref = (pn_rubyref_t *)ptr;
    pn_rubyref_free(rubyref);
  }

  static VALUE rubyref_alloc(VALUE klass) {
    // printf("inside:rubyref_alloc\n");
    pn_rubyref_t *rubyref;
    VALUE object;

    rubyref = pn_rubyref();
    object = Data_Wrap_Struct(klass, rubyref_mark, rubyref_free, rubyref);

    return object;
  }

  static VALUE rubyref_set_ruby_object(VALUE self, VALUE ruby_object) {
    // printf("inside:rubyref_set_ruby_object\n");
    pn_rubyref_t *rubyref;

    Data_Get_Struct(self, pn_rubyref_t, rubyref);
    // printf("\tSetting ruby object to %ld\n", &ruby_object);
    pn_rubyref_set_ruby_object(rubyref, (void *)ruby_object);

    return ruby_object;
  }

  static VALUE rubyref_get_ruby_object(VALUE self) {
    // printf("inside:rubyref_get_ruby_object\n");
    pn_rubyref_t *rubyref;

    Data_Get_Struct(self, pn_rubyref_t, rubyref);
    VALUE result = pn_void2rb(pn_rubyref_get_ruby_object(rubyref));
    // printf("\tGetting ruby object at %ld\n", &result);

    return result;
  }

  static VALUE rubyref_initialize(int argc, VALUE* argv, VALUE self) {
    // printf("inside:rubyref_initialize\n");
    pn_rubyref_t *rubyref;
    VALUE ruby_object;

    Data_Get_Struct(self, pn_rubyref_t, rubyref);
    rb_scan_args(argc, argv, "01", &ruby_object);

    rubyref_set_ruby_object(self, ruby_object);

    return self;
  }

  static void Init_rubyref() {
    mCproton = rb_define_module("Cproton");
    cRubyRef = rb_define_class_under(mCproton, "RubyRef", rb_cObject);
    rb_define_alloc_func(cRubyRef, rubyref_alloc);
    rb_define_method(cRubyRef, "initialize", rubyref_initialize, -1);
    rb_define_method(cRubyRef, "object=", rubyref_set_ruby_object, 1);
    rb_define_method(cRubyRef, "object", rubyref_get_ruby_object, 0);
  }

  %}

#include "engine/engine-internal.h"
#include <proton/rubyref.h>
#include <proton/object.h>
#include <assert.h>

#define pn_rubyref_hashcode NULL
#define pn_rubyref_compare NULL
#define pn_rubyref_inspect NULL

static void pn_rubyref_initialize(void *object) {
  pn_rubyref_t *rubyref = (pn_rubyref_t *)object;

  rubyref->ruby_object = NULL;
}

pn_rubyref_t *pn_rubyref(void) {
  static const pn_class_t clazz = PN_CLASS(pn_rubyref);
  pn_rubyref_t *rubyref = (pn_rubyref_t *)pn_class_new(&clazz, sizeof(pn_rubyref_t));
  rubyref->ruby_object = NULL;
  return rubyref;
}

void pn_rubyref_finalize(void *object) {
  pn_rubyref_t *rubyref = (pn_rubyref_t *)object;
  rubyref->ruby_object = NULL;
}

void pn_rubyref_free(pn_rubyref_t *rubyref) {
  pn_free(rubyref);
}

int pn_rubyref_set_ruby_object(pn_rubyref_t *rubyref, void *object) {
  assert(rubyref);
  rubyref->ruby_object = object;

  return 0;
}

void *pn_rubyref_get_ruby_object(pn_rubyref_t *rubyref) {
  assert(rubyref);
  return rubyref->ruby_object;
}

int pn_rubyref_has_ruby_object(pn_rubyref_t *rubyref) {
  assert(rubyref);
  return (rubyref->ruby_object ? 1 : 0);
}

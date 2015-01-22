#ifndef PROTON_RUBYREF_H
#define PROTON_RUBYREF_H 1

#include <proton/import_export.h>
#include <proton/type_compat.h>
#include <proton/types.h>
#include <stddef.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

  pn_rubyref_t * pn_rubyref(void);
  void pn_rubyref_finalize(void *object);
  void pn_rubyref_free(pn_rubyref_t *rubyref);
  int pn_rubyref_set_ruby_object(pn_rubyref_t *rubyref, void *object);
  void *pn_rubyref_get_ruby_object(pn_rubyref_t *rubyref);
  int pn_rubyref_has_ruby_object(pn_rubyref_t *rubyref);

#ifdef __cplusplus
}
#endif

#endif

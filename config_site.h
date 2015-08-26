/* Site config */
#define PJ_CONFIG_ANDROID 1
#define PJ_CONFIG_MINIMAL_SIZE
/* Disable some codecs */
#define PJMEDIA_HAS_G711_CODEC 0
#define PJMEDIA_HAS_SPEEX_CODEC 0
#define PJMEDIA_HAS_GSM_CODEC 0
#define PJMEIDA_HAS_ILBC_CODEC 0
#include <pj/config_site_sample.h>


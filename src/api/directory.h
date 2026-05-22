#ifndef RMP_DIRECTORY_H
#define RMP_DIRECTORY_H

#include "../third_party/rdn/rdn_native.h"

bool rmp_get_current_path(RDNApi *api);
bool rmp_home_path(RDNApi *api);
bool rmp_list_dir(RDNApi *api);
bool rmp_mkdir(RDNApi *api);
bool rmp_rmdir(RDNApi *api);

#endif

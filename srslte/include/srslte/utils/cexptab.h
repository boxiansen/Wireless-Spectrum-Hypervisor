/**
 *
 * \section COPYRIGHT
 *
 * Copyright 2013-2015 Software Radio Systems Limited
 *
 * \section LICENSE
 *
 * This file is part of the srsLTE library.
 *
 * srsLTE is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * srsLTE is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * A copy of the GNU Affero General Public License can be found in
 * the LICENSE file in the top-level directory of this distribution
 * and at http://www.gnu.org/licenses/.
 *
 */

/******************************************************************************
 *  File:         cexptab.h
 *
 *  Description:  Utility module for generation of complex exponential tables.
 *
 *  Reference:
 *****************************************************************************/

#ifndef CEXPTAB_
#define CEXPTAB_

#include <complex.h>
#include <stdint.h>
#include "srslte/config.h"

typedef struct SRSLTE_API {
  uint32_t size;
  cf_t *tab;
}srslte_cexptab_t;

SRSLTE_API int srslte_cexptab_init(srslte_cexptab_t *nco, 
                                   uint32_t size);

SRSLTE_API void srslte_cexptab_free(srslte_cexptab_t *nco);

SRSLTE_API void srslte_cexptab_gen(srslte_cexptab_t *nco, 
                                   cf_t *x, 
                                   float freq, 
                                   uint32_t len);

SRSLTE_API void srslte_cexptab_gen_direct(cf_t *x, 
                                          float freq, 
                                          uint32_t len);

//******************************************************************************
//********************************** DcF-TDMA **********************************
//******************************************************************************
SRSLTE_API int srslte_cexptab_init_finer(srslte_cexptab_t *h, uint32_t size);

SRSLTE_API void srslte_cexptab_free_finer(srslte_cexptab_t *h);

SRSLTE_API void srslte_cexptab_gen_finer(srslte_cexptab_t *h, cf_t *x, float freq, uint32_t len);

#endif // CEXPTAB_

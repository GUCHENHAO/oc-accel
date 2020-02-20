/*
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __SNAP_H265ENC__
#define __SNAP_H265ENC__

/*
 * This makes it obvious that we are influenced by HLS details ...
 * The ACTION control bits are defined in the following file.
 */

#define GOP_LENGTH              1

#define FRAMEWIDTH              416
#define FRAMEHEIGHT             240

#define QP                      22

#define X_TOTAL                 FRAMEWIDTH-1
#define Y_TOTAL                 FRAMEHEIGHT-1
#define FLAG_SAO_LU             1
#define FLAG_SAO_CH             1
#define ACTION_TYPE_HDL_H265ENC 0x00000001    /* Action Type */

#define REG_START               0x100
#define REG_RUN                 0x104
#define REG_FLG_IRQ             0x108
#define REG_X_TOTAL             0x114
#define REG_Y_TOTAL             0x118
#define REG_FLG_SAO_LU          0x11C
#define REG_FLG_SAO_CH          0x120
#define REG_MOD_RUN             0x124
#define REG_TYP                 0x128
#define REG_QP                  0x12C
#define REG_FTH_SRC_ORI         0x130
#define REG_RDO_DAT_04_ABC      0x158
#define REG_RDO_DAT_08_ABC      0x15C
#define REG_RDO_DAT_16_ABC      0x160
#define REG_RDO_DAT_32_ABC      0x164

#define REG_ORI_LU_BASE_HIGH    0x168
#define REG_ORI_LU_BASE_LOW     0x16C
#define REG_ORI_CH_BASE_HIGH    0x170
#define REG_ORI_CH_BASE_LOW     0x174
#define REG_BS_BASE_HIGH        0x198
#define REG_BS_BASE_LOW         0x19C
#define REG_BS_LEN              0x1A0

#endif    /* __SNAP_H265ENC__ */

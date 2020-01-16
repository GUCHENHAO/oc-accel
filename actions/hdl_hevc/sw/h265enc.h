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

#define FRAMEWIDTH              448
#define FRAMEHEIGHT             256

#define QP                      0x00000016
#define X_TOTAL                 (FRAMEWIDTH /64)-1
#define Y_TOTAL                 (FRAMEHEIGHT /64)-1
#define REC_0_BASE              (FRAMEWIDTH*FRAMEHEIGHT*3/2)*1
#define REC_1_BASE              (FRAMEWIDTH*FRAMEHEIGHT*3/2)*2
#define ACTION_TYPE_HDL_H265ENC 0x00000001    /* Action Type */

#define REG_START               0x100
#define REG_X_TOTAL             0x114
#define REG_Y_TOTAL             0x118
#define REG_QP                  0x12C
#define REG_TYPE                0x128
#define REG_ORI_BASE_HIGH       0x168
#define REG_ORI_BASE_LOW        0x16C
#define REG_REC_0_BASE          0x178
#define REG_REC_1_BASE          0x17C
#define COUNT_A                 0x1A0
#define SYS_DONE_I              0x1F8
#define REG_BS_BASE_HIGH        0x198
#define REG_BS_BASE_LOW         0x19C

#endif    /* __SNAP_H265ENC__ */

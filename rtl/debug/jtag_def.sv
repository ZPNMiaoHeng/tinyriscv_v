 /*                                                                      
 Copyright 2021 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */


`define DbgVersion013       4'h2
`define ProgBufSize         5'h8
`define DataCount           4'h2
`define HaltAddress         64'h800
`define ResumeAddress       `HaltAddress + 4
`define ExceptionAddress    `HaltAddress + 8
`define DataAddr            12'h380

// dmi op
`define DMI_OP_NOP          2'b00
`define DMI_OP_READ         2'b01
`define DMI_OP_WRITE        2'b10

// DM regs addr
`define Data0               6'h04
`define Data1               6'h05
`define Data2               6'h06
`define Data3               6'h07
`define DMControl           6'h10
`define DMStatus            6'h11
`define Hartinfo            6'h12
`define AbstractCS          6'h16
`define Command             6'h17
`define ProgBuf0            6'h20
`define ProgBuf1            6'h21
`define ProgBuf2            6'h22
`define ProgBuf3            6'h23
`define ProgBuf4            6'h24
`define ProgBuf5            6'h25
`define ProgBuf6            6'h26
`define ProgBuf7            6'h27
`define ProgBuf8            6'h28
`define ProgBuf9            6'h29
`define ProgBuf10           6'h2A
`define ProgBuf11           6'h2B
`define ProgBuf12           6'h2C
`define ProgBuf13           6'h2D
`define ProgBuf14           6'h2E
`define ProgBuf15           6'h2F
`define SBAddress3          6'h37
`define SBCS                6'h38
`define SBAddress0          6'h39
`define SBAddress1          6'h3A
`define SBAddress2          6'h3B
`define SBData0             6'h3C
`define SBData1             6'h3D
`define SBData2             6'h3E
`define SBData3             6'h3F

// dmstatus bit index
`define Impebreak           22
`define Allhavereset        19
`define Anyhavereset        18
`define Allresumeack        17
`define Anyresumeack        16
`define Allnonexistent      15
`define Anynonexistent      14
`define Allunavail          13
`define Anyunavail          12
`define Allrunning          11
`define Anyrunning          10
`define Allhalted           9
`define Anyhalted           8
`define Authenticated       7
`define Authbusy            6
`define Hasresethaltreq     5
`define Confstrptrvalid     4
`define Version             3:0

// dmcontrol bit index
`define Haltreq             31
`define Resumereq           30
`define Hartreset           29
`define Ackhavereset        28
`define Hasel               26
`define Hartsello           25:16
`define Hartselhi           15:6
`define Setresethaltreq     3
`define Clrresethaltreq     2
`define Ndmreset            1
`define Dmactive            0

// abstractcs bit index
`define Progbufsize         28:24
`define Busy                12
`define Cmderr              10:8
`define Datacount           3:0

// abstract command access register bit index
`define Cmdtype             31:24
`define Aarsize             22:20
`define Aarpostincrement    19
`define Postexec            18
`define Transfer            17
`define Write               16
`define Regno               15:0

// sbcs bit index
`define Sbversion           31:29
`define Sbbusyerror         22
`define Sbbusy              21
`define Sbreadonaddr        20
`define Sbaccess            19:17
`define Sbautoincrement     16
`define Sbreadondata        15
`define Sberror             14:12
`define Sbasize             11:5
`define Sbaccess128         4
`define Sbaccess64          3
`define Sbaccess32          2
`define Sbaccess16          1
`define Sbaccess8           0


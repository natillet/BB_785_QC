/*
 *  Copyright 2011-12 ARM Limited
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

/*
 * NE10 Library : inc/NE10_types.h
 */

/** NE10 defines a number of types for use in its function signatures.
 *  The types are defined within this header file.
 */

#ifndef NE10_TYPES_H
#define NE10_TYPES_H

/////////////////////////////////////////////////////////
// constant values that are used across the library
/////////////////////////////////////////////////////////
#define NE10_OK 0
#define NE10_ERR -1

/////////////////////////////////////////////////////////
// some external definitions to be exposed to the users
/////////////////////////////////////////////////////////

typedef signed char             ne10_int8_t;
typedef unsigned char           ne10_uint8_t;
typedef signed short            ne10_int16_t;
typedef unsigned short          ne10_uint16_t;
typedef signed int              ne10_int32_t;
typedef unsigned int            ne10_uint32_t;
typedef signed long long int    ne10_int64_t;
typedef unsigned long long int  ne10_uint64_t;
typedef float                   ne10_float32_t;
typedef double                  ne10_float64_t;
typedef int                     ne10_result_t;     // resulting [error-]code

#endif

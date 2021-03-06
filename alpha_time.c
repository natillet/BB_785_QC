#include <stdio.h>
#include <sys/time.h>


#ifndef NEON
void alphaBlend_c(int *fgImage, int *bgImage, int *dstImage);
void alphaBlend_flat(int *fgImage, int *bgImage, int *dstImage);
int backImage[512 * 512];
int foreImage[512 * 512];
int newImage[512 * 512];
#else
#include "NE10_types.h"
extern ne10_result_t alphablend_neon(ne10_int32_t * dst, ne10_int32_t * src1, ne10_int32_t * src2);
ne10_int32_t backImage[512 * 512];
ne10_int32_t foreImage[512 * 512];
ne10_int32_t newImage[512 * 512];
#endif

int main(int argc, char**argv)
{
   FILE *fgFile, *bgFile, *outFile;
   int result;
   struct timeval oldTv, newTv;

   if(argc != 4){
      fprintf(stderr, "Usage:%s foreground background outFile\n",argv[0]);
      return 1;
   }
   fgFile = fopen(argv[1], "rb");
   bgFile = fopen(argv[2], "rb");
   outFile = fopen(argv[3], "wb");

   if(fgFile && bgFile && outFile){
     result = fread(backImage, 512*sizeof(int), 512, bgFile);
     if(result != 512){
       fprintf(stderr, "Error with backImage\n");
       return 3;
     }
     result = fread(foreImage, 512*sizeof(int), 512, fgFile);
     if(result != 512){
       fprintf(stderr, "Error with foreImage\n");
       return 4;
     }
     gettimeofday(&oldTv, NULL);
#ifdef ORIGINAL
     alphaBlend_c(&foreImage[0], &backImage[0], &newImage[0]);
#elif FLAT
     alphaBlend_flat(&foreImage[0], &backImage[0], &newImage[0]);
#elif NEON
	 alphablend_neon(&newImage[0], &foreImage[0], &backImage[0]);
#endif
     gettimeofday(&newTv, NULL);
     fprintf(stdout, "Routine took %d microseconds\n", (int)(newTv.tv_usec - oldTv.tv_usec));
     fwrite(newImage, 512*sizeof(int),512,outFile);
     fclose(fgFile);
     fclose(bgFile);
     fclose(outFile);
     return 0;
   }
   fprintf(stderr, "Problem opening a file\n");
   return 2;
}

#ifndef NEON
#define A(x) (((x) & 0xff000000) >> 24)
#define R(x) (((x) & 0x00ff0000) >> 16)
#define G(x) (((x) & 0x0000ff00) >> 8)
#define B(x) ((x) & 0x000000ff)
#endif

#ifdef ORIGINAL
void alphaBlend_c(int *fgImage, int *bgImage, int *dstImage)
{
  int x, y;
  for(y = 0; y < 512; y++){
     for(x = 0; x < 512; x++){
//  for(y = 0; y < 1; y++){
//     for(x = 0; x < 8; x++){
        int a_fg = A(fgImage[(y*512)+x]);
        int dst_r = ((R(fgImage[(y*512)+x]) * a_fg) + (R(bgImage[(y*512)+x]) * (255-a_fg)))/256;
        int dst_g = ((G(fgImage[(y*512)+x]) * a_fg) + (G(bgImage[(y*512)+x]) * (255-a_fg)))/256;
        int dst_b = ((B(fgImage[(y*512)+x]) * a_fg) + (B(bgImage[(y*512)+x]) * (255-a_fg)))/256;
        dstImage[(y*512)+x] =  0xff000000 |
                              (0x00ff0000 & (dst_r << 16)) |
                              (0x0000ff00 & (dst_g << 8)) |
                              (0x000000ff & (dst_b));
//		printf("a_fg[%d]: %d\n", (y*512)+x, a_fg);
//		printf("dst_r[%d]: %d\n", (y*512)+x, dst_r);
//		printf("dst_g[%d]: %d\n", (y*512)+x, dst_g);
//		printf("dst_b[%d]: %d\n", (y*512)+x, dst_b);
//		printf("dst[%u]: %u\n", (y*512)+x, dstImage[(y*512)+x]);
     }
  }
}
#endif

#ifdef FLAT
void alphaBlend_flat(int *fgImage, int *bgImage, int *dstImage)
{
  int y;
  for(y = 0; y < 262144; y++){
	int a_fg = A(fgImage[y]);
	int dst_r = ((R(fgImage[y]) * a_fg) + (R(bgImage[y]) * (255-a_fg)))/256;
	int dst_g = ((G(fgImage[y]) * a_fg) + (G(bgImage[y]) * (255-a_fg)))/256;
	int dst_b = ((B(fgImage[y]) * a_fg) + (B(bgImage[y]) * (255-a_fg)))/256;
	dstImage[y] =  0xff000000 |
						  (0x00ff0000 & (dst_r << 16)) |
						  (0x0000ff00 & (dst_g << 8)) |
						  (0x000000ff & (dst_b));
  }
}
#endif


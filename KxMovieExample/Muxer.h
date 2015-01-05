//
//  Muxer.h
//  kxmovie
//
//  Created by gxw on 15/1/4.
//
//

#import <Foundation/Foundation.h>

#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"

@interface Muxer : NSObject
- (void)gather;
@end

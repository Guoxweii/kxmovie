//
//  Muxer.m
//  kxmovie
//
//  Created by gxw on 15/1/4.
//
//

#import "Muxer.h"

#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"

@implementation Muxer

- (BOOL)gather:(NSString *)filePath sdpPath:(NSString *)sdpPath {
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    
    [self setState:@"INITIALIZE"];
    
    AVFormatContext *pFormatCtx;
    pFormatCtx = avformat_alloc_context();
    int video_stream_index;
//    char url[]="http://127.0.0.1:8000/test.sdp";
    
    if (avformat_open_input(&pFormatCtx,[sdpPath UTF8String],NULL,NULL) != 0) {
        NSLog(@"can't open stream");
        return FALSE;
    }
    
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        NSLog(@"can't find stream info");
        avformat_close_input(&pFormatCtx);
        return FALSE;
    }
    
    [self setState:@"PROCESS"];
    
    for (int i=0; i<pFormatCtx->nb_streams; i++) {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
        }
    }
    
    AVPacket packet;
    av_init_packet(&packet);
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    filePath = [documentsDirectory stringByAppendingPathComponent:@"test.mp4"];
    
    //open output file
    AVOutputFormat* fmt = av_guess_format(NULL, [filePath UTF8String], NULL);
    AVFormatContext* oc = avformat_alloc_context();
    oc->oformat = fmt;
    avio_open2(&oc->pb, [filePath UTF8String], AVIO_FLAG_WRITE, NULL, NULL);
    
    AVStream* stream=NULL;
    //start reading packets from stream and write them to file

    av_read_play(pFormatCtx);
    
//    int ix = 0;
    while(![[self state] isEqualToString:@"FINISHED"] && av_read_frame(pFormatCtx,&packet)>=0){
        if(packet.stream_index == video_stream_index){
            //packet is video
            if(stream == NULL){
                //create stream in file
//                stream = avformat_new_stream(oc, pFormatCtx->streams[video_stream_index]->codec->codec);
                stream = avformat_new_stream(oc, NULL);
                avcodec_copy_context(stream->codec, pFormatCtx->streams[video_stream_index]->codec);
                stream->sample_aspect_ratio = pFormatCtx->streams[video_stream_index]->codec->sample_aspect_ratio;
                
                // Assume r_frame_rate is accurate
//                stream->r_frame_rate = pFormatCtx->streams[video_stream_index]->r_frame_rate;
//                stream->avg_frame_rate = stream->r_frame_rate;
                stream->time_base = (AVRational){ 1, 25 };
//                stream->codec->time_base = stream->time_base;
                
                avformat_write_header(oc, NULL);
            }
            packet.stream_index = stream->id;
            
//            packet.pts = ix++;
//            packet.dts = packet.pts;
            
//            packet.pts = av_rescale_q_rnd(packet.pts, pFormatCtx->streams[video_stream_index]->codec->time_base, oc->streams[video_stream_index]->time_base,(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
//            packet.dts = av_rescale_q_rnd(packet.dts, pFormatCtx->streams[video_stream_index]->codec->time_base, oc->streams[video_stream_index]->time_base,(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
//            packet.duration = av_rescale_q(packet.duration, pFormatCtx->streams[video_stream_index]->codec->time_base, oc->streams[video_stream_index]->time_base);
//            packet.pos = -1;
            
//            packet.pts = av_rescale_q(packet.pts, pFormatCtx->streams[video_stream_index]->codec->time_base, oc->streams[video_stream_index]->time_base);
//            packet.dts = av_rescale_q(packet.dts, pFormatCtx->streams[video_stream_index]->codec->time_base, oc->streams[video_stream_index]->time_base);
            
            packet.pts *= pFormatCtx->streams[video_stream_index]->codec->ticks_per_frame;
            packet.dts *= pFormatCtx->streams[video_stream_index]->codec->ticks_per_frame;
            
            av_interleaved_write_frame(oc, &packet);
        }
        av_free_packet(&packet);
        av_init_packet(&packet);
    }
    av_read_pause(pFormatCtx);
    av_write_trailer(oc);
    avio_close(oc->pb);
    avformat_free_context(oc);
    avformat_network_deinit();
    
    [self setState:@"SUCCESS"];
    
    NSLog(@"the file path is %@", filePath);
    return TRUE;
}

- (void)stop {
    [self setState:@"FINISHED"];
}

@end
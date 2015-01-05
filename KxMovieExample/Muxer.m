//
//  Muxer.m
//  kxmovie
//
//  Created by gxw on 15/1/4.
//
//

#import "Muxer.h"

@implementation Muxer

- (void)gather {
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    
    AVFormatContext *pFormatCtx;
    pFormatCtx = avformat_alloc_context();
    int video_stream_index;
    char url[]="http://127.0.0.1:8000/test.sdp";
    
    
    if (avformat_open_input(&pFormatCtx,url,NULL,NULL) != 0) {
        NSLog(@"can't open stream");
    }
    
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        NSLog(@"can't find stream info");
        avformat_close_input(&pFormatCtx);
    }
    
    for (int i=0; i<pFormatCtx->nb_streams; i++) {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
        }
    }
    
    AVPacket packet;
    av_init_packet(&packet);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"test.mp4"];
    
    //open output file
    AVOutputFormat* fmt = av_guess_format(NULL, [filePath UTF8String], NULL);
    AVFormatContext* oc = avformat_alloc_context();
    oc->oformat = fmt;
    avio_open2(&oc->pb, [filePath UTF8String], AVIO_FLAG_WRITE, NULL, NULL);
    
    AVStream* stream=NULL;
    //start reading packets from stream and write them to file

    av_read_play(pFormatCtx);
    
    int ix = 0;
    while(av_read_frame(pFormatCtx,&packet)>=0){
        if(packet.stream_index == video_stream_index){
            //packet is video
            if(stream == NULL){
                //create stream in file
                stream = avformat_new_stream(oc, NULL);
                avcodec_copy_context(stream->codec, pFormatCtx->streams[video_stream_index]->codec);
//                stream->sample_aspect_ratio = pFormatCtx->streams[video_stream_index]->codec->sample_aspect_ratio;
                
                stream->sample_aspect_ratio.num = pFormatCtx->streams[video_stream_index]->codec->sample_aspect_ratio.num;
                stream->sample_aspect_ratio.den = pFormatCtx->streams[video_stream_index]->codec->sample_aspect_ratio.den;
                
                // Assume r_frame_rate is accurate
                stream->r_frame_rate = pFormatCtx->streams[video_stream_index]->r_frame_rate;
                stream->avg_frame_rate = stream->r_frame_rate;
                stream->time_base = av_inv_q( stream->r_frame_rate );
                stream->codec->time_base = stream->time_base;
                
                avformat_write_header(oc, NULL);
            }
            packet.stream_index = stream->id;
            
            packet.pts = ix++;
            packet.dts = packet.pts;
            
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
    
    NSLog(@"the file path is %@", filePath);
}

@end
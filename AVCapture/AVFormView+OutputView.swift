//
//  AVFormView+OutputView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

import SwiftUI

extension AVFormView {
    struct OutputView: View {
        @ObservedObject var captureManager: AVCaptureManager

        var body: some View {
            Section("Output") {
                Picker(
                    "Video Codec",
                    selection: $captureManager.movieFileVideoOutputSettings.videoCodec
                ) {
                    Text("Default")
                        .tag(VideoOutputSettings.VideoCodec?.none)

                    ForEach(captureManager.availableVideoCodecs) { videoCodec in
                        Text(videoCodec.name)
                            .tag(videoCodec as VideoOutputSettings.VideoCodec?)
                    }
                }

                Picker(
                    "Audio Codec",
                    selection: $captureManager.movieFileAudioOutputSettings.format
                ) {
                    Text("Default")
                        .tag(AudioOutputSettings.AudioFormat?.none)

                    ForEach(AudioOutputSettings.AudioFormat.allCases) { audioFormat in
                        Text(audioFormat.name)
                            .tag(audioFormat as AudioOutputSettings.AudioFormat?)
                    }
                }
            }
        }
    }
}


struct AVFormView_OutputView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            AVFormView.OutputView(captureManager: AVCaptureManager())
        }
    }
}

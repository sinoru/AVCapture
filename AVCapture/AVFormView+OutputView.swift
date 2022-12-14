//
//  AVFormView+OutputView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVCaptureKit

extension AVFormView {
    struct OutputView: View {
        @ObservedObject var captureManager: AVCaptureManager

        var now: Date {
            let calendar = Calendar.current

            var dateComponents = calendar.dateComponents(in: .current, from: .now)
            dateComponents.nanosecond = nil

            return calendar.date(from: dateComponents) ?? .now
        }

        var body: some View {
            Section("Output Format") {
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

            Section {
                #if os(macOS)
                VStack(alignment: .listRowSeparatorLeading) {
                    Text("Destination")

                    PathControl(
                        allowedTypes: [UTType.directory.identifier],
                        style: .standard,
                        url: $captureManager.movieFileOutputDestinationURL
                    )
                }
                #endif

                TextField("Filename Format", text: $captureManager.movieFileOutputFilenameFormat)
            } header: {
                Text("Output File")
            } footer: {
                TimelineView(.periodic(from: now, by: 1.0)) { timeline in
                    if let movieFileOutputFilename = captureManager.movieFileOutputFileURL(date: timeline.date)?.pathComponents.last {
                        Text(movieFileOutputFilename)
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

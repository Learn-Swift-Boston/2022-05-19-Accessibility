//
//  ContentView.swift
//  AccessibilityDemo
//
//  Created by Zev Eisenberg on 5/19/22.
//

import SwiftUI

enum Loaded<Content> {
    case loaded(Content)
    case error(String)
    case loading
}

struct StarRatingView: View {

    @Binding var value: Int

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { index in
                Button(action: { value = index }) {
                    Image(systemName: value >= index ? "star.fill" : "star")
                }
            }
        }
        .accessibilityRepresentation {
            Slider(value: $value.doubleProxy, in: 1...5, step: 1) {
                Text("Rating")
            }
        }
    }
}

extension Binding where Value: BinaryInteger {
    var doubleProxy: Binding<Double> {
        .init(
            get: {
                Double(wrappedValue)
            },
            set: {
                wrappedValue = Value($0)
            }
        )
    }
}

struct ContentView: View {

    @State var content: Loaded<[RedditPost]> = .loading

    @State var rating: Int = 1

    var body: some View {
        NavigationView {
            VStack {
                Slider(value: $rating.doubleProxy, in: 1...5, step: 1) {
                    Text("Rating")
                }

                StarRatingView(value: $rating)
                    .accessibilityLabel(Text("Rating"))
                List {
                    switch content {
                    case .loaded(let posts):
                        ForEach(posts) { post in
                            PostView(post: post)
                        }
                    case .error(let message):
                        Text("Error loading: \(message)")
                    case .loading:
                        ProgressView()
                    }
                }
                .navigationTitle("My Cool App")
                .task {
                    await fetch()
                }
                .refreshable {
                    await fetch()
            }
            }
        }
    }

    func fetch() async {
        do {
            let data = try await URLSession.shared.data(from: URL(string: "https://reddit.com/r/aww.json")!, delegate: nil).0
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let decoded = try decoder.decode(TopLevelResponse.self, from: data)
            self.content = .loaded(decoded.data.children.map(\.data))
        } catch {
            self.content = .error(error.localizedDescription)
        }
    }
}

struct PostView: View {
    let post: RedditPost

    @Environment(\.displayScale) var displayScale

    var body: some View {
        NavigationLink(
            destination: {
                AsyncImage(url: post.thumbnail, scale: displayScale, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }, placeholder: {
                    Color.gray
                })
            }, label: {
                VStack(alignment: .leading) {
                    AsyncImage(url: post.thumbnail, scale: displayScale, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }, placeholder: {
                        Color.gray
                    })
                    Group {
                        Text(post.title)
                        Text("by u/\(post.author) on \(post.created, format: .dateTime)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .accessibilityHidden(true)
                }
            }
        )
        .accessibilityLabel(post.title)
        .accessibilityAction(named: "Details: by u/\(post.author) on \(post.created, format: .dateTime.day().month().year())") {}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

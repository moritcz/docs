import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Главная")
                }
                .tag(0)

            TransactionListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Записи")
                }
                .tag(1)

            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Статистика")
                }
                .tag(2)
        }
        .tint(Color.notionAccent)
    }
}

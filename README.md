# 🚀 IDEGo

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License MIT">
</p>

IDEGo is a lightweight, lightning-fast macOS Menu Bar application designed for developers to instantly search and launch projects with their favorite IDEs.

IDEGo 是一个轻量级、极速的 macOS 菜单栏应用，专为开发者设计，可让您使用最喜欢的 IDE 即时搜索并启动项目。

---

## ✨ Features / 功能特性

- ⚡️ **Quick Access**: Lives quietly in your menu bar, always one click or shortcut away. (安静驻留菜单栏，随时随地一键唤出)
- 🔍 **Instant Search**: Millisecond-level filtering through your projects using in-memory caching. (毫秒级项目搜索过滤)
- 🧠 **Smart Indexing**:
  - Recursively scans configured directories in the background. (后台递归扫描配置的目录)
  - Respects per-folder depth settings. (支持为每个文件夹单独设置扫描深度)
  - Prioritizes nested project configurations. (智能优先处理嵌套的项目配置)
- 🛠 **Deep Tool Integration**:
  - Automatically detects installed development tools like **Trae, Cursor, IntelliJ IDEA, Xcode**, etc. (自动检测已安装的开发工具)
  - Choose a specific tool on the fly using intuitive keyboard navigation. (支持通过快捷键动态选择特定工具启动项目)
- ⚙️ **Highly Customizable**: Add multiple search paths and adjust scan depths independently. (高度可配置，支持多路径和独立深度)

## 📸 Screenshots / 截图预览

*(Add screenshots of your app here / 在此处添加您的应用截图)*
<!--
![Main Interface](docs/screenshot_main.png)
![Settings](docs/screenshot_settings.png)
-->

## 🚀 Installation / 安装

### Option 1: Build from Source (推荐)

1. Clone the repository (克隆仓库):
   ```bash
   git clone https://github.com/yourusername/idego.git
   cd idego/IDEGo
   ```

2. Run the build script (运行构建脚本):
   ```bash
   ./package_app.sh
   ```

3. The `IDEGo.app` will be generated in the current directory. Move it to your `/Applications` folder.
   (`IDEGo.app` 将生成在当前目录中，将其拖入 `/Applications` 应用程序文件夹即可使用)

## 📖 Usage / 使用方法

1. **Launch (启动)**: Open `IDEGo` from your Applications folder. It will appear as a terminal icon in your menu bar.
2. **Configure (配置)**: 
   - Click the menu bar icon and hit the **gear icon** ⚙️ (or press `Cmd+,`) to open Settings.
   - Click **Add Folder** to add your project directories (e.g., `~/Workspace`).
   - Adjust the slider to set the maximum scan depth for each folder.
3. **Search & Open (搜索与打开)**:
   - Type to search for a project.
   - Use `Up/Down` arrows to navigate the project list.
   - Press `Enter` to confirm a project, then use `Up/Down` to select an IDE from the right sidebar.
   - Press `Enter` again to launch!

## 🤝 Contributing / 参与贡献

Contributions are welcome! Please feel free to submit a Pull Request.
欢迎任何形式的贡献！请随时提交 Pull Request。

1. Fork the Project (复刻项目)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 Credits / 致谢

- **Icons**: The application icons for third-party tools (Cursor, Trae, etc.) are sourced from [macicons](https://macicons.com).
  - *Note: These icons are used for personal/educational purposes to enhance the open-source user experience. All rights to the original brand logos belong to their respective owners.*
- **图标**: 第三方工具（Cursor, Trae 等）的应用图标来源于 [macicons](https://macicons.com)。
  - *注意: 这些图标仅用于个人/教育目的。所有原始品牌徽标的权利归其各自所有者所有。*

## 📄 License / 许可证

Distributed under the MIT License. See `LICENSE` for more information.
本项目采用 MIT 许可证。详情请参阅 `LICENSE` 文件。

---
<p align="center">
  Built with ❤️ by <a href="https://chaordex.com">z @ Chaordex Labs</a>
</p>
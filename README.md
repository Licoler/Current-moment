# Current Moment

Минималистичное iOS-приложение для обмена моментами с друзьями в реальном времени.
Идея — фиксировать и делиться “текущим моментом” без перегрузки интерфейса.

---

## Features

* Захват фото (с fallback на demo-режим)
* Поиск и добавление друзей
* Отправка моментов с подписью
* Просмотр полученных моментов
* Профиль пользователя со статистикой(доработка)
* Widget с последними моментами друзей(в разработке)
* чат с друзьями(в разработке)

---

## Tech Stack

* **Swift**
* **SwiftUI**
* **Combine**
* **MVVM**
* **XCTest**
* **WidgetKit**

---

## Architecture

Приложение построено с использованием MVVM + Repository pattern:

* **View (SwiftUI)** — отображение UI
* **ViewModel** — бизнес-логика + состояние через Combine
* **Repository** — источник данных (mock/demo реализация)
* **Services** — работа с внешними компонентами (например, Widget)

---

## Project Structure

```
currentMoment/
├── App/
    ├──AppCoordinator
    ├──AppDelegate
    ├──AppDependencyContainer
    ├──LaunchViewController
    ├──SceneDelegate
├── Core/
    ├──Extension/
       ├──Date
       ├──UIControl
       ├──UIView
    ├──Infastructure/
       ├──ImagePipeline
       ├──DeepLinkRoute
├── DesignSystem/
    ├──Components/
       ├──AvatarView
       ├──CardContainerView
       ├──IconCircleButton
       ├──PrimaryButton
       ├──ShutterButton
    ├──CMColor
    ├──CMTypography
 ├──Models/
    ├──FriendshipStatus
    ├──Moment
    ├──displayName
    ├──WidgetMomentSnapshot
 ├──Modules/
    ├──Auth/
       ├──AuthViewController
       ├──AuthViewModel
    ├──Camera/
       ├──CameraCaptureMode
       ├──CameraPreviewView
       ├──CameraSessionController
       ├──CameraViewController
       ├──CameraViewModel
       ├──CapturedMomentAsset
       ├──DemoCaptureImageFactory
    ├──Friends/
       ├──FriendsViewController
       ├──FriendsViewModel
       ├──FriendTableViewCell
    ├──History/
       ├──HistoryViewController
       ├──HistoryViewModel
       ├──MomentDetailViewController
       ├──MomentGridCell
    ├──Preview/
       ├──PreviewRecipientCell
       ├──PreviewViewController
       ├──PreviewViewModel
    ├──Profile/
       ├──EditProfileViewController
       ├──ProfileGridCell
       ├──ProfileHeaderView
       ├──ProfileViewController
       ├──ProfileViewModel
       ├──SettingRowView
       ├──SettingRowView
 ├──Recources/
 ├──Services/
    ├──Firebase/
       ├──FirebaseCurrentMomentRepository
    ├──CurrentMomentNotificationServiceProtocol
    ├──CurrentMomentRepositoryProtocol
    ├──CurrentMomentWidgetServiceProtocol
    ├──FirebaseBootstrap
 ├──Utils/
    ├──AppError
    ├──UIColor
    ├──AlertState
├── Widget/
    ├──CurrentMomentEntry
    ├──CurrentMomentWidgetBundle
    ├──CurrentMomentWidgetStore
    ├──WidgetMomentSnapshot
└── Tests/
    ├──CameraViewModelTests
    ├──CurrentMomentRepositoryTests
    ├──FriendsViewModelTests
    ├──PreviewViewModelTests
    ├──ProfileViewModelTests
    ├──TestCurrentMomentWidgetService
```

---

## Testing

В проекте реализованы unit-тесты:

* Repository тесты
* ViewModel тесты
* Проверка Combine publishers

Используется:

* XCTest
* Mock зависимости
---

## Screenshots

> Добавь сюда свои скриншоты (папка `Screenshots` в репозитории)

### Camera

![Camera](Screenshots/camera.png)

### Friends

![Friends](Screenshots/friends.png)

### Preview

![Preview](Screenshots/preview.png)

### Profile

![Profile](Screenshots/profile.png)


---

## Key Decisions

* Используется **Repository pattern** для изоляции слоя данных
* **Mock реализация** упрощает тестирование и разработку
* **Combine** используется для реактивного обновления UI
* ViewModel не зависит от конкретной реализации данных

---

## TODO

* [ ] Интеграция реальной камеры
* [ ] Backend (Firebase / REST API)
* [ ] Авторизация пользователя
* [ ] Улучшение UI/UX
* [ ] Кэширование изображений
* [ ] Обработка ошибок сети

---

## Author

Al'bek Halapov
iOS Developer

Несколько замечаний и напоминаний:

#В виду того, что на симуляторе iPhone 7 и 7s (проблема на устройстве Iphone 7 отсутствует) работает не
корректно метод snapshotView(afterScreenUpdates:), которую я использовал в некоторых анимациях, прошу запускать программу на симмуляторе iPhone 6 или iPhone 6s.

#Программа еще не была оптимизирована под другие размеры экранов Iphone SE, Iphone Plus, поэтому прошу тестировать на устройстве или симуляторе Iphone 6, 6S, 7. В ближайшее время это упущение будет устранено.
 
#Некоторые кнопки и переходы могут не работать, но программа в активной разработке, функционал добавляется, а баги устраняются.
 
#Не лишним будет напомнить, из-за наличия сторонних библиотек и фреймворков запускать файл TwitterTest.xcworkspace

#Для проверки плавности прокрутки (счетчик частоты кадров) в AppDelegate.swift необходимо раздокументировать (uncomment) TWWatchdogInspector.start()
(используя симулятор, частота кадров монитора может давать лаги, поэтому рекомендуется поставить галочку в свойствах симулятора debug ->  Optimize Rendering for Window Scale)
 
Приятного использования:)

p.s. тестовый твиттер аккаунт:
login: @tweeAppTest    password: twitterapp

import Foundation

enum RubBanknotesDataset {
    static let allBanknotes: [BanknoteDefinition] = [
        make5000(),
        make2000(),
        make1000(),
        make500(),
        make200(),
        make100(),
        make50(),
        make10()
    ]

    private static func make5000() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 5000,
            issueYear: 2010,
            series: "Модификация 2010 года",
            frontImageName: "rub5000_front",
            backImageName: "rub5000_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Многотоновый водяной знак с портретом Н.Н. Муравьёва-Амурского",
                    instructions: [
                        "Посмотрите банкноту на просвет",
                        "Найдите портрет в светлой части поля",
                        "Должны быть видны полутона"
                    ],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.08, y: 0.5),
                    region: NormalizedRect(x: 0.02, y: 0.2, width: 0.18, height: 0.6),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .securityThread,
                    title: "Защитная нить",
                    shortDescription: "Внедрённая защитная нить с окнами",
                    instructions: [
                        "Посмотрите банкноту на просвет",
                        "Нить должна выглядеть как сплошная тёмная полоса",
                        "На поверхности видны переливающиеся окна"
                    ],
                    checkMethods: [.onLight, .onAngle],
                    position: NormalizedPoint(x: 0.45, y: 0.1),
                    region: NormalizedRect(x: 0.3, y: 0.0, width: 0.3, height: 0.1),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .microperforation,
                    title: "Микроперфорация",
                    shortDescription: "Отверстия, образующие число «5000»",
                    instructions: [
                        "Посмотрите банкноту на просвет",
                        "В зоне микроперфорации должно быть видно число 5000",
                        "Отверстия не должны прощупываться на ощупь"
                    ],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.85, y: 0.5),
                    region: NormalizedRect(x: 0.78, y: 0.35, width: 0.15, height: 0.3),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .relief,
                    title: "Рельефные элементы",
                    shortDescription: "Выпуклые надписи «БИЛЕТ БАНКА РОССИИ» и метки для людей с ослабленным зрением",
                    instructions: [
                        "Проведите пальцем по надписи «БИЛЕТ БАНКА РОССИИ»",
                        "Ощутите рельеф",
                        "Проверьте метку в левом нижнем углу"
                    ],
                    checkMethods: [.onTouch],
                    position: NormalizedPoint(x: 0.3, y: 0.95),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .kinematicElement,
                    title: "Кинемограмма",
                    shortDescription: "Голограмма с изображением гербов городов",
                    instructions: [
                        "Наклоните банкноту",
                        "Изображение должно меняться и переливаться",
                        "Проверьте чёткость границ элементов"
                    ],
                    checkMethods: [.onAngle],
                    position: NormalizedPoint(x: 0.7, y: 0.4),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .latentImage,
                    title: "Скрытое изображение «РР»",
                    shortDescription: "Скрытые буквы «РР» (реплика)",
                    instructions: [
                        "Посмотрите банкноту под острым углом",
                        "На орнаментальной полосе проявляются буквы «РР»",
                        "Проверьте чёткость букв"
                    ],
                    checkMethods: [.onAngle],
                    position: NormalizedPoint(x: 0.6, y: 0.85),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .microtext,
                    title: "Микротекст",
                    shortDescription: "Микропечать «ЦБ5000РФ» и другие элементы",
                    instructions: [
                        "Возьмите лупу (×10 или больше)",
                        "Найдите микротекст «ЦБ5000РФ»",
                        "Текст должен быть чётким, не размытым"
                    ],
                    checkMethods: [.withMagnifier],
                    position: NormalizedPoint(x: 0.5, y: 0.7),
                    visibleOnSide: .back
                )
            ],
            officialDescription: "Банкнота номиналом 5000 рублей, модификация 2010 года, изготовлена из хлопковой бумаги. Содержит комплекс защитных признаков Банка России.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/5000rub/"),
            supportedChecks: [.watermark, .securityThread, .microperforation, .relief, .kinematicElement, .latentImage, .microtext, .uvFeature, .irFeature, .magneticInk, .protectiveFibers],
            accessibilityDescription: "Банкнота 5000 рублей. Город Хабаровск, мост через реку Амур, памятник Н.Н. Муравьёву-Амурскому."
        )
    }

    private static func make2000() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 2000,
            issueYear: 2017,
            series: "Образца 2017 года",
            frontImageName: "rub2000_front",
            backImageName: "rub2000_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Комбинированный водяной знак с изображением моста и числом «2000»",
                    instructions: ["Посмотрите банкноту на просвет", "Проверьте наличие полутонов и светлого поля"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.1, y: 0.5),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .securityThread,
                    title: "Защитная нить",
                    shortDescription: "Широкая защитная нить с QR-подобными элементами",
                    instructions: ["Посмотрите банкноту на просвет", "На поверхности нити должны быть переливающиеся окна"],
                    checkMethods: [.onLight, .onAngle],
                    position: NormalizedPoint(x: 0.5, y: 0.15),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .kinematicElement,
                    title: "Кинемограмма «2000»",
                    shortDescription: "Элемент с эффектом движения числа «2000»",
                    instructions: ["Наклоните банкноту", "Число «2000» должно перемещаться по горизонтали"],
                    checkMethods: [.onAngle],
                    position: NormalizedPoint(x: 0.7, y: 0.5),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 2000 рублей, выпущена в 2017 году. Русский мост во Владивостоке и космодром «Восточный».",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/2000rub/"),
            supportedChecks: [.watermark, .securityThread, .kinematicElement, .uvFeature, .irFeature, .magneticInk],
            accessibilityDescription: "Банкнота 2000 рублей. Русский мост, космодром Восточный."
        )
    }

    private static func make1000() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 1000,
            issueYear: 2010,
            series: "Модификация 2010 года",
            frontImageName: "rub1000_front",
            backImageName: "rub1000_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Многотоновый водяной знак с памятником Ярославу Мудрому",
                    instructions: ["Посмотрите банкноту на просвет", "Проверьте полутона портрета"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.08, y: 0.5),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .securityThread,
                    title: "Защитная нить",
                    shortDescription: "Внедрённая защитная нить с окнами",
                    instructions: ["Посмотрите банкноту на просвет", "Нить должна быть сплошной тёмной полосой"],
                    checkMethods: [.onLight, .onAngle],
                    position: NormalizedPoint(x: 0.45, y: 0.1),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .microperforation,
                    title: "Микроперфорация",
                    shortDescription: "Отверстия образуют число «1000»",
                    instructions: ["Посмотрите банкноту на просвет", "Должно быть видно число 1000", "Отверстия не должны прощупываться"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.85, y: 0.5),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .relief,
                    title: "Рельефные элементы",
                    shortDescription: "Выпуклые надписи и метка для слабовидящих",
                    instructions: ["Проведите пальцем по надписи «БИЛЕТ БАНКА РОССИИ»"],
                    checkMethods: [.onTouch],
                    position: NormalizedPoint(x: 0.3, y: 0.95),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 1000 рублей, модификация 2010 года. Город Ярославль, памятник Ярославу Мудрому, церковь Иоанна Предтечи.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/1000rub/"),
            supportedChecks: [.watermark, .securityThread, .microperforation, .relief, .kinematicElement, .latentImage, .microtext, .uvFeature, .irFeature, .magneticInk, .protectiveFibers],
            accessibilityDescription: "Банкнота 1000 рублей. Ярославль, памятник Ярославу Мудрому."
        )
    }

    private static func make500() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 500,
            issueYear: 2010,
            series: "Модификация 2010 года",
            frontImageName: "rub500_front",
            backImageName: "rub500_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Многотоновый водяной знак с памятником Петру I",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.08, y: 0.5),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .securityThread,
                    title: "Защитная нить",
                    shortDescription: "Внедрённая защитная нить с окнами",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight, .onAngle],
                    position: NormalizedPoint(x: 0.45, y: 0.1),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .microperforation,
                    title: "Микроперфорация",
                    shortDescription: "Отверстия образуют число «500»",
                    instructions: ["Посмотрите банкноту на просвет", "Должно быть видно число 500"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.85, y: 0.5),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 500 рублей, модификация 2010 года. Город Архангельск, памятник Петру I, Соловецкий монастырь.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/500rub/"),
            supportedChecks: [.watermark, .securityThread, .microperforation, .relief, .kinematicElement, .latentImage, .microtext, .uvFeature, .irFeature, .magneticInk, .protectiveFibers],
            accessibilityDescription: "Банкнота 500 рублей. Архангельск, памятник Петру I."
        )
    }

    private static func make200() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 200,
            issueYear: 2017,
            series: "Образца 2017 года",
            frontImageName: "rub200_front",
            backImageName: "rub200_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Водяной знак с изображением памятника и числом «200»",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.1, y: 0.5),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .kinematicElement,
                    title: "Кинемограмма",
                    shortDescription: "Элемент с эффектом движения числа «200»",
                    instructions: ["Наклоните банкноту"],
                    checkMethods: [.onAngle],
                    position: NormalizedPoint(x: 0.7, y: 0.5),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 200 рублей, выпущена в 2017 году. Севастополь, памятник затопленным кораблям.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/200rub/"),
            supportedChecks: [.watermark, .securityThread, .kinematicElement, .uvFeature, .irFeature, .magneticInk],
            accessibilityDescription: "Банкнота 200 рублей. Севастополь."
        )
    }

    private static func make100() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 100,
            issueYear: 2010,
            series: "Модификация 2010 года",
            frontImageName: "rub100_front",
            backImageName: "rub100_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Водяной знак с портретом Аполлона",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.08, y: 0.5),
                    visibleOnSide: .front
                ),
                SecurityFeature(
                    type: .securityThread,
                    title: "Защитная нить",
                    shortDescription: "Внедрённая защитная нить с окнами",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight, .onAngle],
                    position: NormalizedPoint(x: 0.45, y: 0.1),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 100 рублей, модификация 2010 года. Город Москва, Большой театр, Аполлон.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/100rub/"),
            supportedChecks: [.watermark, .securityThread, .microperforation, .relief, .kinematicElement, .latentImage, .microtext, .uvFeature, .irFeature, .magneticInk, .protectiveFibers],
            accessibilityDescription: "Банкнота 100 рублей. Москва, Большой театр."
        )
    }

    private static func make50() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 50,
            issueYear: 2010,
            series: "Модификация 2010 года",
            frontImageName: "rub50_front",
            backImageName: "rub50_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Водяной знак с изображением Невы и фигуры",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.08, y: 0.5),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 50 рублей, модификация 2010 года. Санкт-Петербург, Дворцовая площадь, ростральная колонна.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/50rub/"),
            supportedChecks: [.watermark, .securityThread, .microperforation, .relief, .kinematicElement, .latentImage, .microtext, .uvFeature, .irFeature, .magneticInk, .protectiveFibers],
            accessibilityDescription: "Банкнота 50 рублей. Санкт-Петербург, Дворцовая площадь."
        )
    }

    private static func make10() -> BanknoteDefinition {
        BanknoteDefinition(
            currency: .rub,
            denominationValue: 10,
            issueYear: 2010,
            series: "Модификация 2010 года",
            frontImageName: "rub10_front",
            backImageName: "rub10_back",
            securityFeatures: [
                SecurityFeature(
                    type: .watermark,
                    title: "Водяной знак",
                    shortDescription: "Локальный водяной знак в виде числа «10»",
                    instructions: ["Посмотрите банкноту на просвет"],
                    checkMethods: [.onLight],
                    position: NormalizedPoint(x: 0.85, y: 0.5),
                    visibleOnSide: .front
                )
            ],
            officialDescription: "Банкнота 10 рублей, модификация 2010 года. Красноярск, часовня Параскевы Пятницы, мост через Енисей.",
            officialSourceURL: URL(string: "https://www.cbr.ru/cash_circulation/banknotes/10rub/"),
            supportedChecks: [.watermark, .securityThread, .relief, .kinematicElement, .microtext, .uvFeature, .magneticInk, .protectiveFibers],
            accessibilityDescription: "Банкнота 10 рублей. Красноярск."
        )
    }
}

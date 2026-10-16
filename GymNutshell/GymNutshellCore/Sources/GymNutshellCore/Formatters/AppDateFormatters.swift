// ⌘
//  GymNutshellCore/Sources/GymNutshellCore/Formatters/AppDateFormatters.swift
//
//  Propósito: Formatters de data reutilizáveis, cacheados como `static let`
//             pra evitar realocação por chamada em listas/widgets.
// ⌘

import Foundation

/// Formatters de data compartilhados entre App, Watch e Widgets.
/// Cada `static let` é instanciado uma vez por processo.
public enum AppDateFormatters {

    /// Chave estável de dia no formato `yyyy-MM-dd`. Independente de locale
    /// (usa `en_US_POSIX`) pra servir como ID determinístico em mapas/persistência.
    public static let dayKey: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Inicial do dia da semana (1 letra), "S", "M", etc. Locale do sistema.
    public static let weekdayInitial: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f
    }()

    /// Data em estilo medium localizado, ex.: "May 16, 2026" / "16 de mai. de 2026".
    public static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    /// Mês e ano localizado em forma standalone, ex.: "May 2026" / "Maio 2026".
    /// Usa `LLLL` (standalone) em vez de `MMMM` pra capitalização correta em
    /// idiomas como pt-BR sem precisar de `.capitalized` manual.
    public static let monthYear: DateFormatter = {
        let f = DateFormatter()
        // Chinês, japonês e coreano escrevem ano antes do mês ("2026年10月"): usa o template do sistema.
        if ["zh", "ja", "ko"].contains(Locale.current.language.languageCode?.identifier ?? "") {
            f.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        } else {
            f.dateFormat = "LLLL yyyy"
        }
        return f
    }()

    /// Só o dia da semana por extenso ("Terça-feira"). Título do calendário nas Conquistas.
    public static func weekday(for date: Date, locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEEE"
        let s = f.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// Dia da semana e dia do mês, sem o mês ("Segunda-feira, 12"). Título da aba Hoje.
    /// O template `EEEEd` sai como "12 Monday" em inglês, então a ordem é montada aqui.
    public static func weekdayAndDay(for date: Date, locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEEE"
        let weekday = f.string(from: date)
        let day = Calendar.current.component(.day, from: date)
        // A ordem e a pontuação vêm da tradução ("%1$@, %2$d", "%2$d日 %1$@"...).
        let format = String(localized: "date.weekdayDay.format", bundle: .gymNutshellCore)
        let s = String(format: format, weekday, day)
        return s.prefix(1).uppercased() + s.dropFirst()
    }
}

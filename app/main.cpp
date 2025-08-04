#include <QtQml/QQmlApplicationEngine>
#include <QtGui/QGuiApplication>

#include <QQmlContext>
#include <QStringList>

#include <QtWidgets/QApplication>
#include <QIcon>
#include <QQuickStyle>

#include <QWindow>
#include <QPainterPath>
#include <QRegion>
#include <QObject>
#include <QDebug>
#include <QScreen>
#include <QRect>

#include <stdlib.h>

#include <QFontDatabase>
#include <QLoggingCategory>

#include <fileio.h>
#include <monospacefontmanager.h>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <csignal>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDir>

QFile *logFile = nullptr;

void logMessage(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    if (!logFile || !logFile->isOpen()) return;

    QTextStream out(logFile);
    out << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz") << " ";

    switch (type) {
        case QtDebugMsg: out << "[DEBUG] "; break;
        case QtInfoMsg: out << "[INFO] "; break;
        case QtWarningMsg: out << "[WARNING] "; break;
        case QtCriticalMsg: out << "[CRITICAL] "; break;
        case QtFatalMsg: out << "[FATAL] "; break;
    }

    out << msg << Qt::endl;
    out.flush();
    if (type == QtFatalMsg) abort();
}

void handleSignal(int signal) {
    if (logFile && logFile->isOpen()) {
        QTextStream out(logFile);
        out << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz")
            << " Caught signal: " << signal << Qt::endl;
        out.flush();
    }
    exit(signal);
}

QString getNamedArgument(QStringList args, QString name, QString defaultName)
{
    int index = args.indexOf(name);
    return (index != -1) ? args[index + 1] : QString(defaultName);
}

QString getNamedArgument(QStringList args, QString name)
{
    return getNamedArgument(args, name, "");
}

int main(int argc, char *argv[])
{
    // Some environmental variable are necessary on certain platforms.

    // This disables QT appmenu under Ubuntu, which is not working with QML apps.
    setenv("QT_QPA_PLATFORMTHEME", "", 1);

    // Disable Connections slot warnings
    QLoggingCategory::setFilterRules("qt.qml.connections.warning=false");

    #if defined (Q_OS_LINUX)
        setenv("QSG_RENDER_LOOP", "threaded", 0);
    #endif

    #if defined(Q_OS_MAC)
        // This allows UTF-8 characters usage in OSX.
        setenv("LC_CTYPE", "UTF-8", 1);
    #endif

    if (argc>1 && (!strcmp(argv[1],"-h") || !strcmp(argv[1],"--help"))) {
        QTextStream cout(stdout, QIODevice::WriteOnly);
        cout << "Usage: " << argv[0] << " [--default-settings] [--workdir <dir>] [--program <prog>] [-p|--profile <prof>] [--fullscreen] [-h|--help]" << endl;
        cout << "  --default-settings  Run cool-retro-term with the default settings" << endl;
        cout << "  --workdir <dir>     Change working directory to 'dir'" << endl;
        cout << "  -e <cmd>            Command to execute. This option will catch all following arguments, so use it as the last option." << endl;
        cout << "  -T <title>          Set window title to 'title'." << endl;
        cout << "  --fullscreen        Run cool-retro-term in fullscreen." << endl;
        cout << "  -p|--profile <prof> Run cool-retro-term with the given profile." << endl;
        cout << "  -h|--help           Print this help." << endl;
        cout << "  --verbose           Print additional information such as profiles and settings." << endl;
        return 0;
    }

    QString appVersion("1.2.0");

    if (argc>1 && (!strcmp(argv[1],"-v") || !strcmp(argv[1],"--version"))) {
        QTextStream cout(stdout, QIODevice::WriteOnly);
        cout << "cool-retro-term " << appVersion << endl;
        return 0;
    }

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_MacDontSwapCtrlAndMeta, true);

    // Add logs
    // Redirect logs to file
    QString logPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/log.txt";
    QDir().mkpath(QFileInfo(logPath).path()); // Ensure directory exists
    logFile = new QFile(logPath);
    if (logFile->open(QIODevice::Append | QIODevice::Text)) {
        freopen(logPath.toUtf8().constData(), "a", stderr);
        qInstallMessageHandler(logMessage);
        qDebug() << "Logging started. Log file at:" << logPath;
    }

    // Catch termination signals
    std::signal(SIGSEGV, handleSignal);
    std::signal(SIGABRT, handleSignal);
    std::signal(SIGFPE, handleSignal);
    std::signal(SIGILL, handleSignal);
    std::signal(SIGTERM, handleSignal);
    QQmlApplicationEngine engine;
    FileIO fileIO;
    MonospaceFontManager monospaceFontManager;

    #if !defined(Q_OS_MAC)
        app.setWindowIcon(QIcon::fromTheme("cool-retro-term", QIcon(":../icons/32x32/cool-retro-term.png")));
    #else
        app.setWindowIcon(QIcon(":../icons/32x32/cool-retro-term.png"));
    #endif

    app.setOrganizationName("cool-retro-term");
    app.setOrganizationDomain("cool-retro-term");

    // Manage command line arguments from the cpp side
    QStringList args = app.arguments();

    // Manage default command
    QStringList cmdList;
    if (args.contains("-e")) {
        cmdList << args.mid(args.indexOf("-e") + 1);
    }
    QVariant command(cmdList.empty() ? QVariant() : cmdList[0]);
    QVariant commandArgs(cmdList.size() <= 1 ? QVariant() : QVariant(cmdList.mid(1)));
    engine.rootContext()->setContextProperty("appVersion", appVersion);
    engine.rootContext()->setContextProperty("defaultCmd", command);
    engine.rootContext()->setContextProperty("defaultCmdArgs", commandArgs);

    engine.rootContext()->setContextProperty("workdir", getNamedArgument(args, "--workdir", "$HOME"));
    engine.rootContext()->setContextProperty("fileIO", &fileIO);
    engine.rootContext()->setContextProperty("monospaceSystemFonts", monospaceFontManager.retrieveMonospaceFonts());

    engine.rootContext()->setContextProperty("devicePixelRatio", app.devicePixelRatio());

    // Manage import paths for Linux and OSX.
    QStringList importPathList = engine.importPathList();
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/qmltermwidget");
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/../PlugIns");
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/../../../qmltermwidget");
    engine.setImportPathList(importPathList);

    engine.load(QUrl(QStringLiteral ("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "Cannot load QML interface";
        return EXIT_FAILURE;
    }

    // Get the root window object
    QWindow *window = qobject_cast<QWindow *>(engine.rootObjects().first());
    if (window) {
        // Set the window to be borderless / frameless
        window->setFlags(Qt::FramelessWindowHint | Qt::Window);
        // Optionally, set other flags such as stay on top:
        // window->setFlags(window->flags() | Qt::WindowStaysOnTopHint);
        int padding = 8;
        // Get the screen geometry
        QScreen *screen = window->screen();
        QRect screenGeometry = screen->geometry();
        // Calculate the window position
        int x = screenGeometry.width() - 400 - padding;
        int y = screenGeometry.height() - 320 - padding;
        // Set the window geometry
        window->setGeometry(x, y, 400, 320);
        QPainterPath path;
    }

    // Quit the application when the engine closes.
    QObject::connect((QObject*) &engine, SIGNAL(quit()), (QObject*) &app, SLOT(quit()));

    return app.exec();
}

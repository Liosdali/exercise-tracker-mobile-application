allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some third-party plugins (e.g. flutter_timezone) ship with a Kotlin
// compile target that doesn't match their own Java compile target, which
// Gradle now treats as a hard error. Force a consistent JVM target across
// every subproject (app + all plugins) to avoid per-plugin breakage.
// Some third-party plugins (e.g. flutter_timezone) ship with a Kotlin
// compile target that doesn't match their own Java compile target, which
// Gradle now treats as a hard error. Align each subproject's Kotlin JVM
// target to whatever Java target Android Gradle Plugin already configured
// for it (rather than forcing a single value, which can break plugins'
// own Android SDK classpath setup).
gradle.projectsEvaluated {
    subprojects {
        val javaTarget = extensions.findByType<com.android.build.gradle.BaseExtension>()
            ?.compileOptions
            ?.targetCompatibility
        if (javaTarget != null) {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget.toString()))
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

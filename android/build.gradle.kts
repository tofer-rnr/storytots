// android/build.gradle.kts (project-level)

import com.android.build.gradle.LibraryExtension
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Put all build outputs under /build at the repo root
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure :app is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

/**
 * Patch for vosk_flutter on AGP 8+:
 *  - Libraries must declare `android.namespace` in Gradle (not in AndroidManifest).
 */
subprojects {
    if (name == "vosk_flutter") {
        plugins.withId("com.android.library") {
            extensions.configure(LibraryExtension::class.java) {
                // Use the SAME id the plugin's manifest used
                namespace = "org.vosk.vosk_flutter"
                compileSdk = 34
                defaultConfig {
                    minSdk = 21
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

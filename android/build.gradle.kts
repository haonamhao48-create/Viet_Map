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
subprojects {
    plugins.withId("com.android.application") {
        val action = Action<Project> {
            configure<com.android.build.gradle.BaseExtension> {
                ndkVersion = "28.2.13676358"
            }
        }
        if (state.executed) {
            action.execute(project)
        } else {
            afterEvaluate(action)
        }
    }
    plugins.withId("com.android.library") {
        val action = Action<Project> {
            configure<com.android.build.gradle.BaseExtension> {
                ndkVersion = "28.2.13676358"
            }
        }
        if (state.executed) {
            action.execute(project)
        } else {
            afterEvaluate(action)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

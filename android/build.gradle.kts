allprojects { repositories { google(); mavenCentral() } }
val output = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(output)
subprojects { layout.buildDirectory.value(output.dir(name)) }
subprojects { evaluationDependsOn(":app") }
tasks.register<Delete>("clean") { delete(output) }

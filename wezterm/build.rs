fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    // Check the *target* OS rather than using `#[cfg(windows)]`: build
    // scripts run on the host, so cfg(windows) would skip embedding the
    // manifest and icon resources when cross compiling for Windows
    // (eg: via cargo-xwin from Linux).
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        use std::io::Write;
        use std::path::Path;

        let repo_dir = std::env::current_dir()
            .ok()
            .and_then(|cwd| cwd.parent().map(|p| p.to_path_buf()))
            .unwrap();
        let windows_dir = repo_dir.join("assets").join("windows");

        // Paths are joined natively (so they also work when cross compiling
        // from a non-Windows host) and escaped for use in an .rc string.
        let rc_path = |p: &Path| p.display().to_string().replace("\\", "\\\\");

        let rcfile_name = Path::new(&std::env::var_os("OUT_DIR").unwrap()).join("resource.rc");
        let mut rcfile = std::fs::File::create(&rcfile_name).unwrap();
        write!(
            rcfile,
            r#"
#include <winres.h>
1 RT_MANIFEST "{manifest}"
"#,
            manifest = rc_path(&windows_dir.join("console.manifest")),
        )
        .unwrap();
        drop(rcfile);

        // Obtain MSVC environment so that the rc compiler can find the right headers.
        // https://github.com/nabijaczleweli/rust-embed-resource/issues/11#issuecomment-603655972
        let target = std::env::var("TARGET").unwrap();
        if let Some(tool) = cc::windows_registry::find_tool(target.as_str(), "cl.exe") {
            for (key, value) in tool.env() {
                std::env::set_var(key, value);
            }
        }
        embed_resource::compile(rcfile_name);
    }
}

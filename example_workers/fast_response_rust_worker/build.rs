fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("cargo:rerun-if-changed=../../priv/protos/queue_service.proto");
    
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .file_descriptor_set_path("proto_descriptor.bin")
        .compile(
            &["../../priv/protos/queue_service.proto"],
            &["../../priv/protos"],
        )?;
    Ok(())
}
fn main() {
    tonic_build::compile_protos("../priv/protos/queue_service.proto").unwrap();
}

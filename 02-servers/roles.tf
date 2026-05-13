# ==============================================================================
# No IAM resources required for client instances.
# Credentials are injected directly into user_data via terraform_remote_state
# from 01-directory — no OCI API calls are needed at instance runtime.
# ==============================================================================

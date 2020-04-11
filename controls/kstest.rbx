# copyright: 2018, The Authors

title "KS Test"

gcp_project_id = attribute("gcp_project_id")

# you add controls here
control "ks-gcp-1" do                                                    # A unique ID for this control
  impact 0.7                                                                         # The criticality, if this control fails.
  title "Just testing..."                            # A human-readable title
  desc "An optional description..."
  describe google_project(project: gcp_project_id) do    # The actual test
    it { should exist }
    its('name') { should eq 'ks4-test-compliant' }
    its('lifecycle_state') { should eq 'ACTIVE' }
  end
end


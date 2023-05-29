/*
Copyright 2023 The Kubebb Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ComponentSpec defines the desired state of Component
type ComponentSpec struct {
}

// ComponentStatus defines the observed state of Component
type ComponentStatus struct {
	// RepositoryRef is a reference to the Repository
	RepositoryRef *corev1.ObjectReference `json:"repository"`
	// The name of the component may come from helm chart name
	Name string `json:"name"`
	// versions contains all version of one component.
	Versions []ComponentVersion `json:"versions"`
	// FIXME: some fields(like description) may change when version update, how to deal with it?
	// A one-sentence description of the chart
	Description string `json:"description,omitempty"`
	// Maintainers is a list of maintainers
	Maintainers []Maintainer `json:"maintainers,omitempty"`
	// The URL to a relevant project page, git repo, or contact person
	Home string `json:"home,omitempty"`
	// Source is the URL to the source code of this Component
	Sources []string `json:"sources,omitempty"`
	// A list of string keywords
	Keywords []string `json:"keywords,omitempty"`
	// The URL to an icon file.
	Icon string `json:"icon,omitempty"`
	// The current component is not in the return list of URLs
	// and will not be deleted but marked as deprecated by this field.
	Deprecated bool `json:"deprecated,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:resource:scope=Namespaced

// Component is the Schema for the components API
// In general, Component will be automatically generated by the controller without user creation
// to display the content of the component in the Repository, Spec should add the necessary
// configuration if possible (currently left blank),
// and Status should display as much information about this component as possible.
// Displaying information in Status ensures that it cannot be unintentionally modified by users.
// Used to management components
// - kubebb-system: public
// - user-namespace: private
type Component struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ComponentSpec   `json:"spec,omitempty"`
	Status ComponentStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// ComponentList contains a list of Component
type ComponentList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Component `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Component{}, &ComponentList{})
}

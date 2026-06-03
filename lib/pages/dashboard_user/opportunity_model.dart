// ===========================================================================
// OPPORTUNITY MODEL
// ===========================================================================

class Opp {
  final String id, title, rate, meta, earning;
  final String? description;
  bool submitted;

  Opp({
    required this.id,
    required this.title,
    required this.rate,
    required this.meta,
    required this.earning,
    this.description,
    this.submitted = false,
  });
}

List<Opp> buildOpps() => [
  Opp(id:'music',   title:'Music Projects Interest Form',                     rate:'\$50–85/hr',  meta:'Remote · Contract', earning:'+ 6K more earning',  submitted: true),
  Opp(id:'qgis',    title:'Geospatial Analysis (QGIS) Specialists',            rate:'\$125/hr',    description:'Use your expertise and creativity in QGIS to create projects to help train AI',                                                                                         meta:'Remote · Contract', earning:'+ 8K more earning'),
  Opp(id:'medical', title:'Medical Imaging & 3D Analysis (3D Slicer)',          rate:'\$125/hr',    description:'Use your expertise and creativity in 3D Slicer to create projects to help train AI',                                                                                   meta:'Remote · Contract', earning:'+ 6K more earning'),
  Opp(id:'para',    title:'Scientific Visualization (ParaView) Specialists',    rate:'\$125/hr',    description:'Use your expertise and creativity in ParaView to create projects to help train AI',                                                                                     meta:'Remote · Contract', earning:'+ 5K more earning',  submitted: true),
  Opp(id:'video',   title:'Video Production Specialists',                       rate:'\$125/hr',    description:'Use your expertise and creativity in Lightworks, Shotcut, or OpenShot to create projects to help train AI',                                                              meta:'Remote · Contract', earning:'+ 11K more earning', submitted: true),
  Opp(id:'game',    title:'Game Development Specialists',                       rate:'\$125/hr',    description:'Use your expertise and creativity in Godot, Defold, Solar 3D, Panda 3D or Stride (Xenko) to create projects to help train AI',                                          meta:'Remote · Contract', earning:'+ 13K more earning'),
  Opp(id:'media',   title:'2D & 3D Digital Media Specialists',                  rate:'\$125/hr',    description:'Use your expertise and creativity in GIMP, Inkscape, Krita, Libresprite, or Blender to create projects to help train AI',                                               meta:'Remote · Contract', earning:'+ 7K more earning'),
  Opp(id:'eda',     title:'Electronics Design & Simulation (EDA Tools)',        rate:'\$125/hr',    description:'Use your experience and creativity in KiCAD, LibrePCB, Qucs-s and Ngspice tools to help train AI',                                                                     meta:'Remote · Contract', earning:'+ 3K more earning'),
  Opp(id:'llm',     title:'LLM Response Quality Evaluator',                     rate:'\$18–25/hr',  description:'Evaluate AI-generated responses for quality, accuracy, and helpfulness to improve model performance.',                                                                  meta:'Remote · Contract', earning:'+ 9K more earning'),
  Opp(id:'annot',   title:'Data Annotation Specialist',                         rate:'\$15–20/hr',  description:'Label and categorize datasets to train machine learning models with high precision.',                                                                                   meta:'Remote · Contract', earning:'+ 4K more earning'),
  Opp(id:'safety',  title:'AI Safety & Alignment Reviewer',                     rate:'\$25–35/hr',  description:'Identify harmful, biased, or unsafe AI outputs to improve model safety and alignment.',                                                                                meta:'Remote · Contract', earning:'+ 5K more earning'),
  Opp(id:'write',   title:'Creative Writing Quality Reviewer',                  rate:'\$20–30/hr',  description:'Assess AI-generated creative content for originality, style, and overall coherence.',                                                                                  meta:'Remote · Contract', earning:'+ 6K more earning'),
];
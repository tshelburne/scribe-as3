﻿/* * This file is part of the DataStore package. * * @author (c) Tim Shelburne <tim@dontlookstudios.com> * * For the full copyright and license information, please view the LICENSE * file that was distributed with this source code. */package dls.datastore {		import dls.datastore.IDataStore;	import dls.datastore.domain.IDomainEntity;	import dls.datastore.factories.IEntityFactory;	import dls.datastore.mappers.IEntityMapper;	import dls.datastore.repositories.EntityRepository;	import dls.datastore.repositories.IEntityRepository;	import dls.datastore.repositories.metadata.ReferenceProperty;	import dls.debugger.Debug;		import flash.utils.describeType;		/*	 * A class to act as an in-memory database for elements built from a JSON configuration.	 */	public class DataStore implements IDataStore {				/*=========================================================*		 * PROPERTIES		 *=========================================================*/				private var _debugOptions:Object = { "source" : "DataStore" };				private var _data:Object;		private var _repos:Vector.<IEntityRepository> = new <IEntityRepository>[];		private var _entityFactory:IEntityFactory;				/*=========================================================*		 * FUNCTIONS		 *=========================================================*/		 		public function DataStore(entityFactory:IEntityFactory) {			_entityFactory = entityFactory;		}				/**		 * pass in an entity type and a configuration to build an entity		 */		public function buildEntity(entityType:String, entityConfig:Object, buildReferences:Boolean = true):void {			getRepository(entityType).add(_entityFactory.build(entityType, entityConfig));						if (buildReferences) {				rebuildReferences();			}		}				/**		 * pass in an entity type and a list of entity configurations to quickly add multiple entities		 */		public function buildEntities(entityType:String, entityConfigs:Array, buildReferences:Boolean = true):void {			Debug.out("Building " + entityType + " entities...", Debug.ACTIONS, _debugOptions);			for each (var entityConfig:Object in entityConfigs) {				buildEntity(entityType, entityConfig, false);			}			Debug.out("Entities built...", Debug.ACTIONS, _debugOptions);						if (buildReferences) {				rebuildReferences();			}		}				/**		 * build all the entity references		 */		private function rebuildReferences():void {						// loop through all repositories to check 			for each (var repo:IEntityRepository in _repos) {								// check whether this repository requires reference building				if (repo.numEntities > 0 && repo.hasReferences()) {					Debug.out("Attempting to add references...", Debug.ACTIONS, _debugOptions);										// loop through all entities in this repository					for each (var entity:IDomainEntity in repo.findAll()) {												// if the entity isn't hydrated, attempt to hydrate it						if (!entity.hydrated) {														// loop through all available reference properties and attempt to fill them							var referencesBuilt:uint = 0;							for each (var referenceProperty:ReferenceProperty in repo.metadata.references) {								var propName:String = referenceProperty.name;								var className:String = referenceProperty.qualifiedClass;								var repository:IEntityRepository = getRepositoryByQualifiedClass(className);								var entityReference:IDomainEntity = repository != null ? repository.find(entity[propName].id) : null;																if (entityReference != null) {									referencesBuilt++;									entity[propName] = entityReference;									Debug.out("Reference property: " + propName + " " + entity[propName].id, Debug.DETAILS, _debugOptions);								}							}														// loop through all available reference collection properties and attempt to fill them							var collectionsBuilt:uint = 0;							for each (var collectionProperty:ReferenceProperty in repo.metadata.referenceCollections) {								var collectionName:String = collectionProperty.name;								var collectionClassName:String = collectionProperty.qualifiedClass;								var collectionRepository:IEntityRepository = getRepositoryByQualifiedClass(collectionClassName);																if (collectionRepository != null) {									var collectionReferencesBuilt:uint = 0;									for (var index:String in entity[collectionName]) {										var collectionEntityReference:IDomainEntity = collectionRepository.find(entity[collectionName][index].id);																				if (collectionEntityReference != null) {											collectionReferencesBuilt++;											entity[collectionName][index] = collectionEntityReference;											Debug.out("Reference collection: " + collectionName + " " + entity[collectionName][index].id, Debug.DETAILS, _debugOptions);										}									}																		if (collectionReferencesBuilt == entity[collectionName].length) {										collectionsBuilt++;									}								}							}														// check whether all references for this entity were built							if (referencesBuilt == repo.metadata.references.length && collectionsBuilt == repo.metadata.referenceCollections.length) {								entity.hydrated = true;								Debug.out("Entity hydrated: " + repo.type + " " + entity.id, Debug.DETAILS, _debugOptions);							}						}					}										Debug.out("Reference attempt completed...", Debug.ACTIONS, _debugOptions);				}			}		}		 		/**		 * return the repository for the given entity type		 */		public function getRepository(type:String):IEntityRepository {			for each (var repo:IEntityRepository in _repos) {				if (repo.canHandle(type)) {					return repo;				}			}						var newRepository:EntityRepository = new EntityRepository(type);			_repos.push(newRepository);			return newRepository;		}		 		/**		 * a convenience function to simplify finding an entity by type and id		 */		public function find(type:String, id:String):IDomainEntity {			return getRepository(type).find(id);		}				/**
		 * find a repository by the fully-qualified class name - assists with building references when properties don't match the repo type
		 */		private function getRepositoryByQualifiedClass(className:String):IEntityRepository {			for each (var repo:IEntityRepository in _repos) {				if (repo.qualifiedClass == className) {					return repo;				}			}						return null;		}	}}